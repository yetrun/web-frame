# frozen_string_literal: true

require_relative 'scope_builders'

# 我们仅把具有内部结构的元素视为 ArrayScope 或 ObjectScope，哪怕它们的 type 是 object 或 array.
module Entities
  class Entity
    class << self
      extend Forwardable

      attr_reader :scope_builder

      def inherited(base)
        base.instance_eval do
          @scope_builder = ObjectScopeBuilder.new
        end
      end

      def_delegator :scope_builder, :property
      def_delegator :scope_builder, :param
      def_delegator :scope_builder, :expose
      def_delegator :scope_builder, :required
      def_delegator :scope_builder, :use
      def_delegator :scope_builder, :to_scope
    end
  end
end
