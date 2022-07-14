# frozen_string_literal: true

module Dain
  module JsonSchema
    class BaseSchemaBuilder
      class << self
        def build(options = {}, path = nil, &block)
          if apply_array_schema?(options, block)
            ArraySchemaBuilder.new(options, &block).to_schema
          elsif apply_object_schema?(options, block)
            ObjectSchemaBuilder.new(options, &block).to_schema
          else
            BaseSchema.new(options, path)
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
