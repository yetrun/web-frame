# frozen_string_literal: true

require_relative '../schemas/ref_schema'

module Meta
  module JsonSchema
    class RefSchemaBuilder
      def initialize(options)
        options = options.dup
        @ref_schema_builder = options.delete(:ref)
        @base_options = options
      end

      def to_schema
        RefSchema.new(@ref_schema_builder.to_schema, @base_options)
      end
    end
  end
end
