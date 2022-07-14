# frozen_string_literal: true

module Dain
  module JsonSchema
    class ArraySchemaBuilder
      def initialize(options, &block)
        raise 'type 选项必须是 array' if !options[:type].nil? && options[:type] != 'array'

        options = options.merge(type: 'array')
        @options = options

        # TODO: 使用 BaseBuilder 如果没有 items
        items_options = options.delete(:items) || {}
        if object_property?(items_options, block)
          @items = ObjectSchemaBuilder.new(items_options, &block).to_schema # TODO: options 怎么办？
        else
          @items = BaseSchema.new(items_options)
        end
      end

      def to_schema
        ArraySchema.new(@items, @options)
      end

      def object_property?(options, block)
        (options && !options[:properties].nil?) || !block.nil?
      end
    end
  end
end
