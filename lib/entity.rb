# frozen_string_literal: true

require_relative 'errors'
require_relative 'json_schema/schemas'

# Dain::Entity 是 ObjectSchemaBuilder 的一个类封装，它不应有自己的逻辑
module Dain
  class Entity
    class << self
      extend Forwardable

      attr_reader :schema_builder

      def inherited(base)
        base.instance_eval do
          @schema_builder = JsonSchema::ObjectSchemaBuilder.new
          @schema_builder.schema_name(proc { |locked_scope|
            generate_schema_name(locked_scope)
          })
        end
      end

      def_delegators :schema_builder, :property, :param, :expose, :use, :lock, :locked, :schema_name, :to_schema

      def method_missing(method, *args)
        if method =~ /^lock_(\w+)$/
          schema_builder.send(method, *args)
        else
          super
        end
      end

      private

      def generate_schema_name(locked_scope)
        return nil unless self.name

        schema_name = self.name.gsub('::', '_')
        if schema_name.end_with?('Entity')
          schema_names = {
            param: schema_name.sub(/Entity$/, 'Params'),
            render: schema_name
          }
        else
          schema_names = {
            param: "#{schema_name}Params",
            render: "#{schema_name}Entity",
          }
        end

        schema_names = schema_names.transform_values { |base_name| "#{base_name}_#{locked_scope}" } if locked_scope
        schema_names
      end
    end
  end
end
