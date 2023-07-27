# frozen_string_literal: true

require 'forwardable'
require_relative 'properties'

module Meta
  module JsonSchema
    class NamedProperties < Properties
      attr_reader :schema_base_name

      def initialize(properties, schema_base_name)
        super(properties)

        raise TypeError, "schema_name 必须是一个 String，当前是：#{schema_base_name.class}" unless schema_base_name.is_a?(String)
        raise ArgumentError, 'schema_name 不能为 nil 或空字符串' if schema_base_name.nil? || schema_base_name.empty?

        # 修正 base_name，确保其不包含 Entity 后缀
        schema_base_name = schema_base_name.delete_suffix('Entity') if schema_base_name&.end_with?('Entity')
        @schema_base_name = schema_base_name
      end

      def schema_name(stage)
        if stage == :render
          "#{schema_base_name}Entity"
        elsif stage == :param
          "#{schema_base_name}Params"
        else
          raise ArgumentError, "stage 必须是 :render 或 :param，当前是：#{stage}"
        end
      end

      def merge(other_properties)
        raise UnsupportedError, 'NamedProperties 不支持 merge 操作'
      end
    end
  end
end
