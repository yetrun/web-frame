# frozen_string_literal: true

require_relative '../../utils/kwargs/check'

module Meta
  module JsonSchema
    class ObjectSchema < BaseSchema
      attr_reader :properties, :locked_options

      USER_OPTIONS_CHECKER = Utils::KeywordArgs::Builder.build do
        permit_extras true

        key :scope, normalizer: ->(value) {
          raise ArgumentError, 'scope 选项不可传递 nil' if value.nil?
          value = [value] unless value.is_a?(Array)
          value
        }
      end

      def initialize(properties: {}, options: {}, locked_options: {}, schema_name_resolver: proc { nil })
        super(options)

        @properties = properties || {} # property 包含 stage，stage 包含 scope、schema
        @properties = Properties.new(@properties) if @properties.is_a?(Hash)
        @locked_options = USER_OPTIONS_CHECKER.check(locked_options || {})
        @schema_name_resolver = schema_name_resolver || proc { nil }
      end

      # 复制一个新的 ObjectSchema，只有 options 不同
      def dup(options)
        self.class.new(
          properties: properties,
          options: options,
          locked_options: locked_options,
          schema_name_resolver: @schema_name_resolver
        )
      end

      def filter(object_value, user_options = {})
        # 合并 user_options
        user_options = user_options.merge(locked_options) if locked_options
        user_options = USER_OPTIONS_CHECKER.check(user_options)

        object_value = super(object_value, user_options)
        return nil if object_value.nil?

        # 第一步，根据 user_options[:scope] 需要过滤一些字段
        stage = user_options[:stage]
        # 传递一个数字；因为 scope 不能包含数字，这里传递一个数字，使得凡是配置 scope 的属性都会被过滤
        user_scope = user_options[:scope] || [0]
        exclude = user_options.delete(:exclude) # 这里删除 exclude 选项，不要传递给下一层
        properties = @properties.filter_by(stage: stage, user_scope: user_scope)
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
      # > 每个 ObjectSchema 拥有一个 @schema_name_resolver 实例变量，如果由它解析出来的名称不为 nil，
      # > 则该 Schema 生成文档时会使用 $ref 格式。除非 to_ref 选项设置为 false.
      #
      def to_schema_doc(user_options)
        Utils::KeywordArgs.check(
          args: user_options,
          schema: { stage: nil, scope: nil, to_ref: false, schemas: nil }
        )

        stage = user_options[:stage]
        locked_scopes = (locked_options || {})[:scope] || []
        schema_name = @schema_name_resolver.call(stage, locked_scopes)
        if schema_name && user_options[:to_ref] != false
          # 首先将 Schema 写进 schemas 选项中去
          schemas = user_options[:schemas]
          unless schemas.key?(schema_name)
            schemas[schema_name] = nil # 首先设置 schemas 防止出现无限循环
            schemas[schema_name] = to_schema_doc(**user_options, to_ref: false) # 原地修改 schemas，无妨
          end

          return { '$ref': "#/components/schemas/#{schema_name}" }
        end

        properties = @properties.filter_by(stage: stage, user_scope: locked_scopes)
        required_keys = properties.filter do |key, property_schema|
          property_schema.options[:required]
        end.keys
        properties = properties.transform_values do |property_schema |
          property_schema.to_schema_doc(**user_options, to_ref: true)
        end

        schema = { type: 'object' }
        schema[:description] = options[:description] if options[:description]
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
