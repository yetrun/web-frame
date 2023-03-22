require_relative 'base_schema'

module Meta
  module JsonSchema
    class DynamicSchema < BaseSchema
      def initialize(resolver, one_of: nil, **base_options)
        super(base_options)

        @resolver = resolver
        @one_of = one_of
      end

      def filter(value, user_options = {})
        value = super(value, user_options)
        schema = @resolver.call(value).to_schema
        schema.filter(value, user_options)
      end

      def to_schema_doc(user_options)
        schema = { type: 'object' }
        schema[:oneOf] = @one_of.map do |schema|
          schema.to_schema_doc(user_options)
        end if @one_of

        schema
      end
    end
  end
end
