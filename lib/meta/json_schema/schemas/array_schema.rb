# frozen_string_literal: true

module Meta
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

      def to_schema_doc(user_options = {})
        stage_options = user_options[:stage] == :param ? @param_options : @render_options

        schema = {
          type: 'array',
          items: @items ? @items.to_schema_doc(user_options) : {}
        }
        schema[:description] = stage_options[:description] if stage_options[:description]
        schema
      end
    end
  end
end
