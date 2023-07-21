# frozen_string_literal: true

module Meta
  module JsonSchema
    class ScopingSchema < BaseSchema
      attr_reader :on, :schema

      def initialize(required_scope: [], schema:)
        raise ArgumentError, 'required_scope 选项不可传递 nil' if required_scope.nil?
        required_scope = [required_scope] unless required_scope.is_a?(Array)

        @on = required_scope
        @schema = schema
      end

      def scoped(user_scopes)
        return schema if (on - user_scopes).empty? # required_scopes 应被消耗殆尽

        UnsupportedSchema.new(:on, user_scopes)
      end

      STAGING_SCHEMA_OPTIONS = Utils::KeywordArgs::Builder.build do
        permit_extras true

        # TODO: 如果我想把 on 改名为 require_scopes，关键字参数的机制是否支持？
        key :on, alias_names: [:scope], default: [], normalizer: ->(required_scopes) {
          required_scopes = [] if required_scopes.nil?
          required_scopes = [required_scopes] unless required_scopes.is_a?(Array)
          required_scopes
        }
      end
      def self.build_from_options(options, build_schema)
        options = STAGING_SCHEMA_OPTIONS.check(options)
        required_scope = options.delete(:on) || []
        schema = build_schema.call(options)
        schema = ScopingSchema.new(required_scope: required_scope, schema: schema) unless required_scope.empty?
        schema
      end
    end
  end
end
