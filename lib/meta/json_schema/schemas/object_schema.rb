# frozen_string_literal: true

require_relative '../../utils/kwargs/check'

module Meta
  module JsonSchema
    class ObjectSchema < BaseSchema
      attr_reader :properties, :locked_options

      USER_OPTIONS_CHECKER = Utils::KeywordArgs::Builder.build do
        permit_extras true

        key :scope, normalizer: ->(value) {
          raise ArgumentError, 'scope 选项不可传递 nil' if value.nil?
          value = [value] unless value.is_a?(Array)
          value
        }
      end

      def initialize(properties: nil, options: {}, locked_options: {}, schema_name_resolver: proc { nil })
        super(options)

        @properties = properties || Properties.new({}) # property 包含 stage，stage 包含 scope、schema
        @properties = Properties.new(@properties) if @properties.is_a?(Hash)
        @locked_options = USER_OPTIONS_CHECKER.check(locked_options || {})
        @schema_name_resolver = schema_name_resolver || proc { nil }
      end

      # 复制一个新的 ObjectSchema，只有 options 不同
      def dup(options)
        self.class.new(
          properties: properties,
          options: options,
          locked_options: locked_options,
          schema_name_resolver: @schema_name_resolver
        )
      end

      def filter(object_value, user_options = {})
        # 合并 user_options
        user_options = user_options.merge(locked_options) if locked_options
        user_options = USER_OPTIONS_CHECKER.check(user_options)
        super
      end

      # 合并其他的属性，并返回一个新的 ObjectSchema
      def merge_other_properties(properties)
        ObjectSchema.new(properties: self.properties.merge(properties))
      end

      def resolve_name(stage)
        locked_scopes = (locked_options || {})[:scope] || []
        @schema_name_resolver.call(stage, locked_scopes)
      end

      def to_schema_doc(stage: nil, **user_options)
        locked_scopes = (locked_options || {})[:scope] || []

        schema = { type: 'object' }
        schema[:description] = options[:description] if options[:description]

        properties, required_keys = @properties.to_swagger_doc(stage: stage, locked_scopes: locked_scopes, **user_options)
        schema[:properties] = properties unless properties.empty?
        schema[:required] = required_keys unless required_keys.empty?
        schema
      end

      def locked_scope
        locked_options && locked_options[:scope]
      end

      def locked_exclude
        locked_options && locked_options[:exclude]
      end

      private

      def filter_internal(object_value, user_options)
        @properties.filter(object_value, user_options)
      end
    end
  end
end
