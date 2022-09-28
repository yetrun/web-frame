# frozen_string_literal: true

require_relative 'errors'
require_relative 'json_schema/schemas'

# 我们仅把具有内部结构的元素视为 ArrayScope 或 ObjectScope，哪怕它们的 type 是 object 或 array.
module Dain
  module Entities
    # TODO: 更名为 Dain::Entity
    class Entity
      class << self
        extend Forwardable

        attr_reader :scope_builder

        def inherited(base)
          base.instance_eval do
            @scope_builder = JsonSchema::ObjectSchemaBuilder.new
          end
        end

        def_delegator :scope_builder, :property
        def_delegator :scope_builder, :param
        def_delegator :scope_builder, :expose
        def_delegator :scope_builder, :required
        def_delegator :scope_builder, :use
        def_delegator :scope_builder, :to_schema
        def_delegator :scope_builder, :lock_scope
        def_delegator :scope_builder, :lock_exclude
      end
    end
  end
end
