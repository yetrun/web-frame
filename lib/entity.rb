# frozen_string_literal: true

require_relative 'errors'
require_relative 'json_schema/schemas'

# 我们仅把具有内部结构的元素视为 ArrayScope 或 ObjectScope，哪怕它们的 type 是 object 或 array.
module Dain
  class Entity
    class << self
      extend Forwardable

      attr_reader :scope_builder

      def inherited(base)
        base.instance_eval do
          @scope_builder = JsonSchema::ObjectSchemaBuilder.new
        end
      end

      def_delegators :scope_builder, :property, :param, :expose, :required, :use, :lock

      def method_missing(method, *args)
        if method =~ /^lock_(\w+)$/
          scope_builder.send(method, *args)
        else
          super
        end
      end

      def to_schema(locked_options = nil)
        scope_builder.to_schema(locked_options, schema_name)
      end

      def schema_name(name = nil)
        if name
          @schema_name = name
        else
          @schema_name || generate_schema_name
        end
      end

      private

      def generate_schema_name
        return nil unless self.name

        schema_name = self.name.gsub('::', '_')
        if schema_name.end_with?('Entity')
          {
            param: schema_name.sub(/Entity$/, 'Params'),
            render: schema_name
          }
        else
          {
            param: "#{schema_name}Params",
            render: "#{schema_name}Entity",
          }
        end
      end
    end
  end
end
