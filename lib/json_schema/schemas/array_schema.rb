# frozen_string_literal: true

module JsonSchema
  class ArraySchema < BaseSchema
    attr_reader :items

    def initialize(items, options = {})
      super(options)

      @items = items
    end

    def filter(array_value, options = {})
      path = options[:root] || ''

      array_value = super(array_value, options)
      return nil if array_value.nil?
      raise Errors::EntityInvalid.new(path => '参数应该传递一个数组') unless array_value.respond_to?(:each_with_index)

      array_value.each_with_index.map do |item, index|
        p = "#{path}[#{index}]"
        @items.filter(item, **options, root: p)
      end
    end

    def to_schema # TODO: change name to to_schema_doc
      schema = {
        type: 'array',
        items: @items ? @items.to_schema : {}
      }
      schema[:description] = options[:description] if options[:description]
      schema
    end
  end
end
