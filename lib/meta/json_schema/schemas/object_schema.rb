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

      # stage 和 scope 选项在两个 CHECKER 下都用到了
      USER_OPTIONS_CHECKER = Utils::KeywordArgs::Builder.build do
        key :stage
        key :scope, normalizer: ->(value) {
          raise ArgumentError, 'scope 选项不可传递 nil' if value.nil?
          value = [value] unless value.is_a?(Array)
          value
        }
        key :discard_missing, :exclude, :extra_properties, :type_conversion, :validation
        key :execution, :user_data, :object_value
      end
      TO_SCHEMA_DOC_CHECKER = Utils::KeywordArgs::Builder.build do
        key :stage
        key :scope, normalizer: ->(value) {
          raise ArgumentError, 'scope 选项不可传递 nil' if value.nil?
          value = [value] unless value.is_a?(Array)
          value
        }
        key :schema_docs_mapping, :defined_scopes_mapping
      end

      def initialize(properties:, options: {}, locked_options: {})
        raise ArgumentError, 'properties 必须是 Properties 实例' unless properties.is_a?(Properties)

        super(options)

        @properties = properties || Properties.new({}) # property 包含 stage，stage 包含 scope、schema
        @properties = Properties.new(@properties) if @properties.is_a?(Hash)
        @locked_options = USER_OPTIONS_CHECKER.check(locked_options || {})
      end

      def filter(object_value, user_options = {})
        # 合并 user_options
        user_options = USER_OPTIONS_CHECKER.check(user_options)
        user_options = self.class.merge_user_options(user_options, locked_options) if locked_options
        super
      end

      def to_schema_doc(user_options = {})
        user_options = TO_SCHEMA_DOC_CHECKER.check(user_options)
        user_options = self.class.merge_user_options(user_options, locked_options) if locked_options

        schema = { type: 'object' }
        schema[:description] = options[:description] if options[:description]
        properties, required_keys = @properties.to_swagger_doc(**user_options)
        schema[:properties] = properties unless properties.empty?
        schema[:required] = required_keys unless required_keys.empty?
        schema
      end

      def naming?
        properties.is_a?(NamedProperties)
      end

      def defined_scopes(stage:, defined_scopes_mapping:)
        properties.defined_scopes(stage: stage, defined_scopes_mapping: defined_scopes_mapping)
      end

      # 解析当前 Schema 的名称
      #
      # 名称解析的规则是：
      # 1. 结合基础的 schema_name，如果它是参数，就加上 Params 后缀；如果它是返回值，就加上 Entity 后缀
      # 2. 而后跟上 locked_scope. 这里，会把多余的 scope 去掉。比如，一个实体内部只处理 Admin 的 scope，但是外部传进来了
      #    Admin 和 Detail，那么名称只会包括 Admin
      def resolve_name(stage, user_scopes, defined_scopes)
        raise ArgumentError, 'stage 不能为 nil' if stage.nil?

        # 先合成外面传进来的 scope
        locked_scopes = (locked_options || {})[:scope] || []
        user_scopes = (user_scopes + locked_scopes).uniq

        # 再根据 stage 和 scope 生成为当前的 Schema 生成一个合适的名称，要求保证唯一性
        base_schema_name = properties.schema_name(stage)

        # 将调用转移到 Scopes 模块下
        Scopes::Utils.resolve_name(base_schema_name, user_scopes, defined_scopes)
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
