# frozen_string_literal: true

require_relative '../../utils/kwargs/check'
require_relative 'named_properties'

module Meta
  module JsonSchema
    class ObjectSchema < BaseSchema
      attr_reader :properties
      # 只有 ObjectSchema 对象才有 locked_options，因为 locked_options 多是用来锁定属性的行为的，包括：
      # scope:、discard_missing:、exclude: 等
      attr_reader :locked_options

      USER_OPTIONS_CHECKER = Utils::KeywordArgs::Builder.build do
        permit_extras true

        key :scope, normalizer: ->(value) {
          raise ArgumentError, 'scope 选项不可传递 nil' if value.nil?
          value = [value] unless value.is_a?(Array)
          value
        }
      end

      def initialize(properties:, options: {}, locked_options: {})
        raise ArgumentError, 'properties 必须是 Properties 实例' unless properties.is_a?(Properties)

        super(options)

        @properties = properties || Properties.new({}) # property 包含 stage，stage 包含 scope、schema
        @properties = Properties.new(@properties) if @properties.is_a?(Hash)
        @locked_options = USER_OPTIONS_CHECKER.check(locked_options || {})
      end

      # 复制一个新的 ObjectSchema，只有 options 不同
      def dup(options)
        raise UnsupportedError, 'dup 不应该再执行了'

        self.class.new(
          properties: properties,
          options: options,
          locked_options: locked_options,
        )
      end

      def filter(object_value, user_options = {})
        # 合并 user_options
        user_options = USER_OPTIONS_CHECKER.check(user_options)
        user_options = self.class.merge_user_options(user_options, locked_options) if locked_options
        super
      end

      # 合并其他的属性，并返回一个新的 ObjectSchema. 注意，这个方法会丢弃 ObjectSchema 原本的 options、locked_options 等，
      # 只保留了合并后的 properties.
      def merge_other_properties(properties)
        raise UnsupportedError, 'merge_other_properties 不应该再执行了'

        ObjectSchema.new(properties: self.properties.merge(properties))
      end

      def naming?
        properties.is_a?(NamedProperties)
      end

      def resolve_name(stage, user_scope)
        # 先合成外面传进来的 scope
        locked_scopes = (locked_options || {})[:scope] || []
        scope = user_scope + locked_scopes

        # 再根据 stage 和 scope 生成为当前的 Schema 生成一个合适的名称，要求保证唯一性
        stage = :render if stage.nil?
        schema_name = properties.schema_name
        schema_name += 'Params' if stage == :param
        schema_name += 'Entity' if stage == :render
        schema_name += "_#{scope.join('_')}" unless scope.empty?
        schema_name
      end

      def to_schema_doc(user_options = {})
        user_options = USER_OPTIONS_CHECKER.check(user_options)
        user_options = self.class.merge_user_options(user_options, locked_options) if locked_options

        schema = { type: 'object' }
        schema[:description] = options[:description] if options[:description]

        properties, required_keys = @properties.to_swagger_doc(**user_options)
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

      def self.merge_user_options(user_options, locked_options)
        user_options.merge(locked_options) do |key, user_value, locked_value|
          if key == :scope
            user_value + locked_value
          else
            locked_value
          end
        end
      end
    end
  end
end
