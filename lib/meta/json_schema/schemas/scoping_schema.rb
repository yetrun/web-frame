# frozen_string_literal: true

module Meta
  module JsonSchema
    class ScopingSchema < BaseSchema
      attr_reader :scope, :schema

      def initialize(scope: :all, schema:)
        scope = :all if scope.nil?
        scope = [scope] unless scope.is_a?(Array) || scope == :all
        if scope.is_a?(Array) && scope.any? { |s| s.is_a?(Integer) }
          raise ArgumentError, 'scope 选项内不可传递数字'
        end

        @scope = scope
        @schema = schema
      end

      def scoped(user_scope)
        return schema if @scope == :all
        return schema if (user_scope - @scope).empty? # user_scope 应被消耗殆尽

        UnsupportedSchema.new(:scope, user_scope)
      end

      def self.build_from_options(options, build_schema)
        options = options.dup
        scope = options.delete(:scope)
        schema = build_schema.call(options)
        scope ? ScopingSchema.new(scope: scope, schema: schema) : schema
      end
    end
  end
end
