# frozen_string_literal: true

require_relative '../support/scope_matcher'

module Meta
  module JsonSchema
    class ScopingSchema < BaseSchema
      attr_reader :scope_matcher, :schema

      def initialize(scope_matcher_options: , schema:)
        @scope_matcher = ScopeMatcher.new(scope_matcher_options)
        @schema = schema
      end

      def scoped(user_scopes)
        @scope_matcher.match?(user_scopes) ? schema : unsupported_schema(user_scopes)
      end

      private

      def unsupported_schema(user_scopes)
        UnsupportedSchema.new(:scope, user_scopes)
      end

      def self.build_from_options(options, build_schema)
        options = options.dup
        scope_matcher_options = options.delete(:scope)
        schema = build_schema.call(options)
        schema = ScopingSchema.new(scope_matcher_options: scope_matcher_options, schema: schema) if scope_matcher_options
        schema
      end
    end
  end
end
