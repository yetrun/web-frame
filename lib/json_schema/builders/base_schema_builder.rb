# frozen_string_literal: true

module Dain
  module JsonSchema
    class BaseSchemaBuilder
      class << self
        def build(options = {}, path = nil, &block)
          if apply_array_scope?(options, block)
            ArraySchemaBuilder.new(options, &block).to_scope
          elsif apply_object_scope?(options, block)
            ObjectSchemaBuilder.new(options, &block).to_scope
          else
            BaseSchema.new(options, path)
          end
        end

        private

        def apply_array_scope?(options, block)
          options[:type] == 'array' && (options[:items] || block)
        end

        def apply_object_scope?(options, block)
          # TODO: 有点问题
          (options[:type] == 'object' || block) && (options[:properties] || block)
        end
      end
    end
  end
end
