# frozen_string_literal: true

require_relative 'base_schema'

module Meta
  module JsonSchema
    class RefSchema < BaseSchema
      attr_reader :object_schema

      def initialize(object_schema, options = {})
        raise ArgumentError, 'object_schema 必须是一个 ObjectSchema' unless object_schema.is_a?(ObjectSchema)

        super(options)
        @object_schema = object_schema
      end

      def filter(value, user_options = {})
        value = super
        object_schema.filter(value, user_options)
      end

      def to_schema_doc(user_options)
        raise '引用的 ObjectSchema 没有包含命名逻辑，无法生成文档' unless object_schema.naming?

        # 首先，要求出 defined_scopes
        defined_scopes = self.defined_scopes(stage: user_options[:stage], defined_scopes_mapping: user_options[:defined_scopes_mapping])
        # 然后，求出 schema_name
        schema_name = object_schema.resolve_name(user_options[:stage], user_options[:scope], defined_scopes)
        # 接着将 Schema 写进 schemas 选项中去
        schema_components = user_options[:schema_docs_mapping] || {}
        unless schema_components.key?(schema_name)
          schema_components[schema_name] = nil # 首先设置 schemas 防止出现无限循环
          schema_components[schema_name] = object_schema.to_schema_doc(**user_options) # 原地修改 schemas，无妨
        end

        # 最后，返回这个 $ref 结构
        { '$ref': "#/components/schemas/#{schema_name}" }
      end

      def defined_scopes(stage:, defined_scopes_mapping:)
        defined_scopes_mapping ||= {}

        if object_schema.properties.respond_to?(:schema_name)
          # 只有命名实体才会被缓存
          schema_name = object_schema.properties.schema_name(stage)
          return defined_scopes_mapping[schema_name] if defined_scopes_mapping.key?(schema_name)
        end

        defined_scopes_mapping[schema_name] = []
        # 求解 defined_scopes，最终结果去重 + 排序
        defined_scopes = object_schema.properties.each.map do |name, property|
          property.defined_scopes(stage: stage, defined_scopes_mapping: defined_scopes_mapping)
        end.flatten.uniq.sort_by(&:name)
        defined_scopes_mapping[schema_name] = defined_scopes
        defined_scopes
      end
    end
  end
end
