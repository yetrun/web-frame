# frozen_string_literal: true

module Dain
  module JsonSchema
    class ObjectSchema < BaseSchema
      attr_reader :properties, :object_validations, :locked_options, :schema_names

      def initialize(properties: {}, object_validations: {}, options: {}, locked_options: nil, schema_names: nil)
        super(options)

        @properties = properties
        @object_validations = object_validations
        @locked_options = locked_options

        schema_names = { param: schema_names, render: schema_names } if schema_names.is_a?(String)
        @schema_names = schema_names
      end

      # 复制一个新的 ObjectSchema，只有 options 不同
      def dup(options)
        self.class.new(
          properties: self.properties,
          object_validations: self.object_validations,
          options: options,
          locked_options: self.locked_options,
          schema_names: self.schema_names
        )
      end

      def filter(object_value, user_options = {})
        # 合并 user_options
        user_options = user_options.merge(locked_options) if locked_options

        object_value = super(object_value, user_options)
        return nil if object_value.nil?

        # 第一步，根据 user_options[:scope] 需要过滤一些字段
        # user_options[:scope] 应是一个数组
        user_scope = user_options[:scope] || []
        user_scope = [user_scope] unless user_scope.is_a?(Array)
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
          next false if user_scope.empty?
          (user_scope - scope_option).empty? # user_scope 应被消耗殆尽
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

      # 合并其他的属性，并返回一个新的 ObjectSchema
      def merge(properties)
        ObjectSchema.new(properties: self.properties.merge(properties))
      end

      # 生成 Swagger 文档的 schema 格式。
      #
      # 选项：
      # - stage: 传递 :param 或 :render
      # - schemas: 用于保存已经生成的 Schema
      # - to_ref: 是否生成 $ref 格式，默认为“是”
      #
      # 提示：
      # > 每个 ObjectSchema 拥有一个 schema_names 方法。如果这个方法返回的内容不为 nil，则该 Schema 生成文档时会
      # > 使用 $ref 格式。除非 to_ref 选项设置为 false.
      #
      def to_schema_doc(user_options)
        stage = user_options[:stage]
        if schema_names && user_options[:to_ref] != false
          schema_name = schema_names[stage]

          # 首先将 Schema 写进 schemas 选项中去
          schemas = user_options[:schemas]
          unless schemas.key?(schema_name)
            schemas[schema_name] = nil # 首先设置 schemas 防止出现无限循环
            schemas[schema_name] = to_schema_doc(**user_options, to_ref: false) # 原地修改 schemas，无妨
          end

          return { '$ref': "#/components/schemas/#{schema_name}" }
        end

        stage_options = options(stage)
        user_scope = locked_scope || []
        user_scope = [user_scope] unless user_scope.is_a?(Array)
        properties = @properties.filter do |name, property_schema|
          # 根据 stage 过滤
          next false if stage.nil?
          next false if stage == :param && !property_schema.options(:param)
          next false if stage == :render && !property_schema.options(:render)

          # 根据 locked_scope 过滤
          scope_option = property_schema.options(stage, :scope)
          scope_option = [scope_option] unless scope_option.is_a?(Array)
          next true if scope_option.empty?
          next false if user_scope.empty?
          (user_scope - scope_option).empty? # user_scope 应被消耗殆尽
        end
        required_keys = properties.filter do |key, property_schema|
          property_schema.options(stage, :required)
        end.keys
        properties = properties.transform_values do |property_schema|
          property_schema.to_schema_doc(**user_options, to_ref: true)
        end

        schema = { type: 'object' }
        schema[:description] = stage_options[:description] if stage_options[:description]
        schema[:properties] = properties unless properties.empty?
        schema[:required] = required_keys unless required_keys.empty?
        schema
      end

      def locked_scope
        locked_options && locked_options[:scope]
      end

      def locked_exclude
        locked_options && locked_options[:exclude]
      end

      private

        def resolve_property_value(object_value, name, property_schema, stage)
          if property_schema.value?(stage)
            nil
          elsif object_value.is_a?(Hash) || object_value.is_a?(ObjectWrapper)
            object_value.key?(name.to_s) ? object_value[name.to_s] : object_value[name.to_sym]
          else
            raise "不应该还有其他类型了，已经在类型转换中将其转换为 Dain::JsonSchema::ObjectWrapper 了"
          end
        end
    end
  end
end
