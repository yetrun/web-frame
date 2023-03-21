# frozen_string_literal: true

require_relative '../schemas/dynamic_schema'

module Meta
  module JsonSchema
    class SchemaBuilderTool
      class << self
        def build(options = {}, &block)
          if apply_array_schema?(options, block)
            ArraySchemaBuilder.new(options, &block).to_schema
          elsif apply_object_schema?(options, block)
            ObjectSchemaBuilder.new(options, &block).to_schema
          elsif options[:using]
            options = options.dup
            using = options.delete(:using)
            using = { resolve: using } if using.is_a?(Proc)
            DynamicSchema.new(
              resolve: using[:resolve],
              one_of: using[:one_of] && using[:one_of].map { |schema| RefSchema.new(schema.to_schema) },
              **options
            )
          else
            BaseSchema.new(options)
          end
        end

        private

        def apply_array_schema?(options, block)
          options[:type] == 'array' && (options[:items] || block)
        end

        def apply_object_schema?(options, block)
          (options[:type] == 'object' || options[:type].nil?) && (options[:properties] || block)
        end
      end
    end
  end
end
