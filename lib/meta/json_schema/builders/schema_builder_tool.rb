# frozen_string_literal: true

require_relative 'ref_schema_builder'
require_relative 'dynamic_schema_builder'
require_relative 'array_schema_builder'
require_relative 'object_schema_builder'
require_relative '../schemas/staging_schema'

module Meta
  module JsonSchema
    class SchemaBuilderTool
      class << self
        SCHEMA_BUILDER_OPTIONS = Utils::KeywordArgs::Builder.build do
          permit_extras true

          key :ref, alias_names: [:using], normalizer: ->(entity) {
            entity
          }
          key :dynamic_ref, alias_names: [:dynamic_using], normalizer: ->(value) { value.is_a?(Proc) ? { resolve: value } : value }
        end
        def build(options = {}, &block)
          options = SCHEMA_BUILDER_OPTIONS.check(options)

          if apply_array_schema?(options, block)
            ArraySchemaBuilder.new(options, &block).to_schema
          elsif apply_ref_schema?(options, block)
            RefSchemaBuilder.new(options).to_schema
          elsif apply_dynamic_schema?(options, block)
            DynamicSchemaBuilder.new(options).to_schema
          elsif apply_object_schema?(options, block)
            ObjectSchemaBuilder.new(options, &block).to_schema
          else
            BaseSchema.new(options)
          end
        end

        private

        def apply_array_schema?(options, block)
          options[:type] == 'array'
        end

        def apply_object_schema?(options, block)
          (options[:type] == 'object' || options[:type].nil?) && (options[:properties] || block)
        end

        def apply_ref_schema?(options, block)
          options[:ref] != nil
        end

        def apply_dynamic_schema?(options, block)
          options[:dynamic_ref] != nil
        end
      end
    end
  end
end
