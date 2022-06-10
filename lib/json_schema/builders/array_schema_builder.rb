# frozen_string_literal: true

module JsonSchema
  class ArraySchemaBuilder
    def initialize(options, &block)
      options = options.dup
      @options = options

      # TODO: 使用 BaseBuilder 如果没有 items
      items_options = options.delete(:items) || {}
      if object_property?(items_options, block)
        @items = ObjectSchemaBuilder.new(items_options, &block).to_scope # TODO: options 怎么办？
      else
        @items = BaseSchema.new(items_options)
      end
    end

    def to_scope
      ArraySchema.new(@items, @options)
    end

    def object_property?(options, block)
      (options && options[:properties] != nil) || block != nil
    end
  end
end
