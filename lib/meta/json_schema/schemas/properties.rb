# frozen_string_literal: true

require 'forwardable'

module Meta
  module JsonSchema
    class Properties
      class StagingProperty
        def initialize(param:, render:, none:)
          @param_stage = param
          @render_stage = render
          @none_stage = none
        end

        def stage(stage = nil)
          case stage
          when :param
            @param_stage
          when :render
            @render_stage
          else
            @none_stage
          end
        end

        def stage?(stage)
          stage(stage) != nil
        end

        def schema(stage = nil)
          stage(stage).schema
        end

        def self.build(options, build_schema)
          param_opts, render_opts, common_opts = SchemaOptions.divide_to_param_and_render(options)

          StagingProperty.new(
            param: options[:param] === false ? nil : ScopingProperty.build(param_opts, build_schema),
            render: options[:render] === false ? nil : ScopingProperty.build(render_opts, build_schema),
            none: ScopingProperty.build(common_opts, build_schema)
          )
        end
      end

      class ScopingProperty
        attr_reader :scope, :schema

        def initialize(scope: :all, schema:)
          scope = :all if scope.nil?
          scope = [scope] unless scope.is_a?(Array) || scope == :all
          if scope.is_a?(Array) && scope.any? { |s| s.is_a?(Integer) }
            raise ArgumentError, 'scope 选项内不可传递数字'
          end
          @scope = scope

          @schema = schema
        end

        def self.build(options, build_schema)
          options = options.dup
          scope = options.delete(:scope)
          schema = build_schema.call(options)
          ScopingProperty.new(scope: scope, schema: schema)
        end
      end

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
        filtered_properties = properties.filter do |name, property|
          # 通过 discard_missing 过滤
          next false if user_options[:discard_missing] && !object_value.key?(name.to_s)

          # 通过 locked_exclude 选项过滤
          next false if exclude && exclude.include?(name)

          # 默认返回 true
          next true
        end

        # 第二步，递归过滤每一个属性
        object = {}
        errors = {}
        filtered_properties.each do |name, property_schema|
          value = resolve_property_value(object_value, name, property_schema, stage)

          begin
            object[name] = property_schema.filter(value, **user_options, object_value: object_value)
          rescue JsonSchema::ValidationErrors => e
            errors.merge! e.prepend_root(name).errors
          end
        end.to_h

        if errors.empty?
          object
        else
          raise JsonSchema::ValidationErrors.new(errors)
        end
      end

      def to_swagger_doc(locked_scopes:, stage:, **user_options)
        properties = filter_by(stage: stage, user_scope: locked_scopes)
        required_keys = properties.filter do |key, property_schema|
          property_schema.options[:required]
        end.keys
        properties = properties.transform_values do |property_schema |
          property_schema.to_schema_doc(stage: stage, **user_options)
        end
        [properties, required_keys]
      end

      # 程序中有些地方用到了这三个方法
      def_delegators :@properties, :empty?, :key?, :[]

      def self.build_property(*args)
        StagingProperty.build(*args)
      end

      private

      def filter_by(stage:, user_scope: false)
        properties = @properties.filter do |name, property|
          # 通过 stage 过滤。
          next false unless property.stage?(stage)
          property = property.stage(stage)

          # 通过 user_scope 过滤
          next true if property.scope == :all
          (user_scope - property.scope).empty? # user_scope 应被消耗殆尽
        end
        properties.transform_values do |property|
          property.stage(stage).schema
        end
      end

      def resolve_property_value(object_value, name, property_schema, stage)
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
