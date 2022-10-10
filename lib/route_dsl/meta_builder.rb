# frozen_string_literal: true

module Dain
  module RouteDSL
    class MetaBuilder
      # TODO: meta 参数没必要了
      def initialize(&block)
        @meta = {}

        instance_exec &block if block_given?
      end

      def build
        @meta
      end

      def params(options = {}, &block)
        @meta[:params_schema] = JsonSchema::BaseSchemaBuilder.build(options, &block)
      end

      def status(code, *other_codes, &block)
        codes = [code, *other_codes]
        entity_schema = JsonSchema::BaseSchemaBuilder.build(&block)
        @meta[:responses] = @meta[:responses] || {}
        codes.each { |code| @meta[:responses][code] = entity_schema }
      end

      [:tags, :title, :description].each do |method_name|
        define_method(method_name) do |value|
          @meta[method_name] = value
        end
      end

      module Delegator
        [:params, :status, :tags, :title, :description].each do |method_name|
          define_method(method_name) do |*args, &block|
            @meta_builder.send(method_name, *args, &block)
            self
          end
        end
      end
    end
  end
end
