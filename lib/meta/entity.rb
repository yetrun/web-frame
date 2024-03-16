# frozen_string_literal: true

require 'forwardable'
require_relative 'errors'
require_relative 'json_schema/schemas'

module Meta
  class Entity
    class << self
      extend Forwardable

      attr_reader :schema_builder

      def inherited(base)
        base.instance_eval do
          @schema_builder = JsonSchema::ObjectSchemaBuilder.new
          @schema_builder.schema_name(self.name) if self.name
        end
      end

      def method_missing(method, *args, **kwargs, &)
        schema_builder.send(method, *args, **kwargs, &)
      end
    end
  end
end