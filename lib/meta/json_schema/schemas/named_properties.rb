# frozen_string_literal: true

require 'forwardable'
require_relative 'properties'

module Meta
  module JsonSchema
    class NamedProperties < Properties
      attr_reader :schema_name

      def initialize(properties, schema_name)
        super(properties)

        raise TypeError, "schema_name 必须是一个 String，当前是：#{schema_name.class}" unless schema_name.is_a?(String)
        raise ArgumentError, 'schema_name 不能为 nil 或空字符串' if schema_name.nil? || schema_name.empty?

        # 修正 base_name，确保其不包含 Entity 后缀
        schema_name = schema_name.delete_suffix('Entity') if schema_name&.end_with?('Entity')
        @schema_name = schema_name
      end
    end
  end
end
