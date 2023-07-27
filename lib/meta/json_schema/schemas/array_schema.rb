# frozen_string_literal: true

module Meta
  module JsonSchema
    class ArraySchema < BaseSchema
      extend Forwardable

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

      def_delegator :@items, :defined_scopes

      private

      def filter_internal(array_value, user_options)
        if array_value.respond_to?(:each_with_index)
          array_value = array_value
        elsif array_value.respond_to?(:to_a)
          array_value = array_value.to_a
        else
          raise ValidationError.new('参数应该传递一个数组或者数组 Like 的对象（实现了 each_with_index 或者 to_a 方法）')
        end

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
