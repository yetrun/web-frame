# frozen_string_literal: true

module Dain
  module RouteDSL
    class UniformedParamsBuilder
      def initialize(&block)
        @parameters = {}
        @request_body_builder = JsonSchema::ObjectSchemaBuilder.new

        instance_exec &block if block_given?
      end

      def param(name, options = {}, &block)
        options = options.dup
        op_in = options.delete(:in) || 'body'

        if op_in == 'body'
          property name, options, &block
        else
          @parameters[name] = { in: op_in, schema: JsonSchema::BaseSchema.new(options) }
        end
      end

      def property(name, options = {}, &block)
        @request_body_builder.property name, options, &block
      end

      def build
        [@parameters, @request_body_builder.to_schema]
      end
    end
  end
end
