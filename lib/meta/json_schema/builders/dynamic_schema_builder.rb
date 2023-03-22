# frozen_string_literal: true

require_relative '../schemas/dynamic_schema'

module Meta
  module JsonSchema
    class DynamicSchemaBuilder
      def initialize(options)
        options = options.dup
        @dynamic_schema_options = options.delete(:dynamic_ref)
        @base_options = options
      end

      def to_schema
        DynamicSchema.new(
          @dynamic_schema_options[:resolve],
          one_of: @dynamic_schema_options[:one_of] && @dynamic_schema_options[:one_of].map { |schema| RefSchema.new(schema.to_schema) },
          **@base_options
        )
      end
    end
  end
end
