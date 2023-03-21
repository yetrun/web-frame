# frozen_string_literal: true

require_relative 'base_schema'

module Meta
  module JsonSchema
    class RefSchema < BaseSchema
      attr_reader :schema

      def initialize(schema, options = {})
        super(options)
        @schema = schema
      end

      def filter(value, user_options = {})
        value = super
        schema.filter(value, user_options)
      end

      def to_schema_doc(user_options)
        schema_name = schema.resolve_name(user_options[:stage])

        # 首先将 Schema 写进 schemas 选项中去
        schema_components = user_options[:schemas]
        unless schema_components.key?(schema_name)
          schema_components[schema_name] = nil # 首先设置 schemas 防止出现无限循环
          schema_components[schema_name] = schema.to_schema_doc(**user_options) # 原地修改 schemas，无妨
        end

        # 返回的是 $ref 结构
        { '$ref': "#/components/schemas/#{schema_name}" }
      end
    end
  end
end
