# frozen_string_literal: true

require 'forwardable'

module Meta
  module JsonSchema
    class Properties
      extend Forwardable

      def initialize(properties)
        @properties = properties
      end

      def filter(object_value, user_options = {})
        # 第一步，根据 user_options[:scope] 需要过滤一些字段
        stage = user_options[:stage]
        # 传递一个数字；因为 scope 不能包含数字，这里传递一个数字，使得凡是配置 scope 的属性都会被过滤
        user_scope = user_options[:scope] || [0]
        exclude = user_options.delete(:exclude) # 这里删除 exclude 选项，不要传递给下一层
        properties = filter_by(stage: stage, user_scope: user_scope)
        filtered_properties = properties.filter do |name, property_schema|
          # 通过 discard_missing 过滤
          next false if user_options[:discard_missing] && !object_value.key?(name.to_s)

          # 通过 locked_exclude 选项过滤
          next false if exclude && exclude.include?(name)

          # 通过 if 选项过滤
          next false unless property_schema.if?(user_options)

          # 默认返回 true
          next true
        end

        # 第二步，递归过滤每一个属性
        object = {}
        errors = {}
        cause = nil
        filtered_properties.each do |name, property_schema|
          value = resolve_property_value(object_value, name, property_schema)

          begin
            object[name] = property_schema.filter(value, **user_options, object_value: object_value)
          rescue JsonSchema::ValidationErrors => e
            cause = e.cause || e if cause.nil? # 将第一次出现的错误作为 cause
            errors.merge! e.prepend_root(name).errors
          end
        end.to_h

        # 第三步，检测是否有剩余的属性
        if user_options[:extra_properties] == :raise_error && !(object_value.keys.map(&:to_sym) - properties.keys).empty?
          raise JsonSchema::ValidationError, '遇到多余的属性'
        end

        if errors.empty?
          object
        elsif cause
          begin
            raise cause
          rescue
            raise JsonSchema::ValidationErrors.new(errors)
          end
        else
          raise JsonSchema::ValidationErrors.new(errors)
        end
      end

      def to_swagger_doc(scope: [], stage: nil, **user_options)
        locked_scopes = scope
        properties = filter_by(stage: stage, user_scope: locked_scopes)
        required_keys = properties.filter do |key, property_schema|
          property_schema.options[:required]
        end.keys
        properties = properties.transform_values do |property_schema |
          property_schema.to_schema_doc(stage: stage, scope: scope, **user_options)
        end
        [properties, required_keys]
      end

      # 程序中有些地方用到了这三个方法
      def_delegators :@properties, :empty?, :key?, :[]

      def merge(properties)
        self.class.new(@properties.merge(properties.instance_eval { @properties }))
      end

      def self.build_property(*args)
        StagingSchema.build_from_options(*args)
      end

      private

      def filter_by(stage:, user_scope: false)
        @properties.transform_values do |property|
          property.find_schema(stage: stage, scope: user_scope)
        end.filter do |name, schema|
          schema.filter?
        end
      end

      def resolve_property_value(object_value, name, property_schema)
        if property_schema.value?
          nil
        elsif object_value.is_a?(Hash) || object_value.is_a?(ObjectWrapper)
          object_value.key?(name.to_s) ? object_value[name.to_s] : object_value[name.to_sym]
        else
          raise "不应该还有其他类型了，已经在类型转换中将其转换为 Meta::JsonSchema::ObjectWrapper 了"
        end
      end
    end
  end
end
