# frozen_string_literal: true

module Dain
  module JsonSchema
    class ObjectSchema < BaseSchema
      attr_reader :properties, :object_validations, :locked_options

      # TODO: 定义 locked_* 方法
      def locked_scope
        locked_options && locked_options[:scope]
      end

      def locked_exclude
        locked_options && locked_options[:exclude]
      end

      def initialize(properties = {}, object_validations = {}, options = {}, locked_options = nil)
        super(options)

        @properties = properties
        @object_validations = object_validations
        @locked_options = locked_options
      end

      def filter(object_value, user_options = {})
        # 合并 user_options
        user_options = user_options.merge(locked_options) if locked_options

        object_value = super(object_value, user_options)
        return nil if object_value.nil?

        # 第一步，根据 user_options[:scope] 需要过滤一些字段
        # user_options[:scope] 应是一个数组
        scope_filter = user_options[:scope] || []
        scope_filter = [scope_filter] unless scope_filter.is_a?(Array)
        stage = user_options[:stage]
        exclude = user_options.delete(:exclude) # 这里删除 exclude 选项
        filtered_properties = @properties.filter do |name, property_schema|
          # 通过 discard_missing 过滤
          next false if user_options[:discard_missing] && !object_value.key?(name.to_s)

          # 通过 stage 过滤。
          property_schema_options = property_schema.options(stage)
          next false unless property_schema_options

          # 通过 locked_exclude 选项过滤
          next false if exclude && exclude.include?(name)

          # 通过 scope 过滤
          scope_option = property_schema_options[:scope]
          next true if scope_option.empty?
          next false if scope_filter.empty?
          (scope_filter - scope_option).empty? # scope_filter 应被消耗殆尽
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

      # 生成 Swagger 文档的 schema 格式，所谓 schema 格式，是指形如
      #
      #     {
      #       type: 'object',
      #       properties: {
      #         ...
      #       }
      #     }
      #
      # 的格式。
      def to_schema_doc(user_options = {})
        stage = user_options[:stage]
        stage_options = options(stage)

        properties = @properties.filter do |name, property_schema|
          # 首先要通过 stage 过滤
          next false unless property_schema.options(:param)
          # 然后过滤掉非 body 参数
          next false unless property_schema.options(:param, :in) == 'body'

          true
        end.transform_values do |property_schema|
          property_schema.to_schema_doc
        end

        if properties.empty?
          nil
        else
          schema = {
            type: 'object',
            properties: properties,
          }
          schema[:description] = stage_options[:description] if stage_options[:description]
          schema
        end
      end

      # 生成 Swagger 文档的 parameters 部分，这里是指生成路径位于 `path`、`query`、`header` 的参数。
      def generate_parameters_doc
        doc = []

        # 提取根路径的所有 `:in` 选项不为 `body` 的元素（默认值为 `body`）
        @properties.each do |key, property_schema| 
          # 首先要通过 stage 过滤
          next unless property_schema.options(:param)
          # 然后过滤掉 body 参数
          next if property_schema.options(:param, :in) == 'body'

          property_options = property_schema.param_options
          doc << {
            name: key,
            in: property_options[:in],
            type: property_options[:type],
            required: property_options[:required] || false,
            description: property_options[:description] || ''
          }
        end

        doc
      end

      private

        def resolve_property_value(object_value, name, property_schema, stage)
          if property_schema.value?(stage)
            nil
          elsif object_value.is_a?(Hash) || object_value.is_a?(ObjectWrapper)
            value = object_value.key?(name.to_s) ? object_value[name.to_s] : object_value[name.to_sym]
          else
            raise "不应该还有其他类型了，已经在类型转换中将其转换为 Dain::JsonSchema::ObjectWrapper 了"
          end
        end
    end
  end
end
