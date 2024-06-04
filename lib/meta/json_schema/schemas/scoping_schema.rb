# frozen_string_literal: true

require_relative '../support/scope_matcher'
require_relative '../../scope/utils'

module Meta
  module JsonSchema
    class ScopingSchema < BaseSchema
      attr_reader :scope_matcher, :schema

      def initialize(scope_matcher:, schema:)
        # raise ArgumentError, 'scope_matcher 不能是一个数组' if scope_matcher.is_a?(Array)

        @scope_matcher = Scope::Utils.parse(scope_matcher)
        @schema = schema
      end

      def scoped(user_scopes)
        @scope_matcher.match?(user_scopes) ? schema : unsupported_schema(user_scopes)
      end

      def defined_scopes(**kwargs)
        current = scope_matcher.defined_scopes
        deep = schema.defined_scopes(**kwargs)
        (current + deep).uniq
      end

      private

      def unsupported_schema(user_scopes)
        UnsupportedSchema.new(:scope, user_scopes)
      end

      def self.build_from_options(options, build_schema)
        options = options.dup
        scope_matcher_options = options.delete(:scope)
        schema = build_schema.call(options)
        schema = ScopingSchema.new(scope_matcher: scope_matcher_options, schema: schema) if scope_matcher_options
        schema
      end
    end
  end
end
