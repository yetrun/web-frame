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

      def_delegators :scope_builder, :property, :param, :expose, :required, :use, :lock, :to_schema

      def method_missing(method, *args)
        if method =~ /^lock_(\w+)$/
          scope_builder.send(method, *args)
        else
          super
        end
      end
    end
  end
end
