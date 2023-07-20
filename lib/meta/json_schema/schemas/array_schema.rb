# frozen_string_literal: true

module Meta
  module JsonSchema
    class ArraySchema < BaseSchema
      attr_reader :items

      def initialize(items, options = {})
        super(options)

        @items = items
      end

      def to_schema_doc(**user_options)
        stage_options = options

        schema = {
          type: 'array',
          items: @items ? @items.to_schema_doc(**user_options) : {}
        }
        schema[:description] = stage_options[:description] if stage_options[:description]
        schema
      end

      private

      def filter_internal(array_value, user_options)
        raise ValidationError.new('参数应该传递一个数组') unless array_value.respond_to?(:each_with_index)
        array_value.each_with_index.map do |item, index|
          begin
            @items.filter(item, user_options)
          rescue ValidationErrors => e
            raise e.prepend_root("[#{index}]")
          end
        end
      end
    end
  end
end
