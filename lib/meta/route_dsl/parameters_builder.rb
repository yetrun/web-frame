# frozen_string_literal: true

module Meta
  module RouteDSL
    class ParametersBuilder
      def initialize(&block)
        @parameters = {}

        instance_exec &block if block_given?
      end

      def param(name, options)
        options = options.dup
        op_in = options.delete(:in) || 'query'

        @parameters[name] = { in: op_in, schema: JsonSchema::BaseSchema.new(options) }
      end

      def build
        @parameters
      end
    end
  end
end
