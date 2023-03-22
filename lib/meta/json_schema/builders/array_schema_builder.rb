# frozen_string_literal: true

module Meta
  module JsonSchema
    class ArraySchemaBuilder
      def initialize(options, &block)
        options = options.dup
        if options[:items]
          items_options = options.delete(:items)
        elsif options[:ref]
          items_options = { ref: options.delete(:ref) }
        elsif options[:dynamic_ref]
          items_options = { dynamic_ref: options.delete(:dynamic_ref) }
        else
          items_options = {}
        end
        @items_schema = SchemaBuilderTool.build(items_options, &block)
        @base_options = options
      end

      def to_schema
        ArraySchema.new(@items_schema, @base_options)
      end

      def object_property?(options, block)
        (options && !options[:properties].nil?) || !block.nil?
      end
    end
  end
end
