# frozen_string_literal: true

module Dain
  module JsonSchema
    class ArraySchema < BaseSchema
      attr_reader :items

      def initialize(items, options = {})
        super(options)

        @items = items
      end

      def filter(array_value, options = {})
        array_value = super(array_value, options)
        return nil if array_value.nil?
        raise ValidationError.new('参数应该传递一个数组') unless array_value.respond_to?(:each_with_index)

        array_value.each_with_index.map do |item, index|
          begin
            @items.filter(item, **options)
          rescue ValidationErrors => e
            raise e.prepend_root("[#{index}]")
          end
        end
      end

      def to_schema_doc
        schema = {
          type: 'array',
          items: @items ? @items.to_schema_doc : {}
        }
        schema[:description] = options[:description] if options[:description]
        schema
      end
    end
  end
end
