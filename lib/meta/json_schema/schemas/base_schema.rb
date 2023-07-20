# frozen_string_literal: true

require_relative '../../utils/kwargs/check'
require_relative '../support/schema_options'

module Meta
  module JsonSchema
    class BaseSchema
      OPTIONS_CHECKER = Utils::KeywordArgs::Builder.build do
        key :type, :items, :description, :presenter, :value, :default, :properties, :convert
        key :validate, :required, :format, :allowable
        key :param, :render
        key :before, :after
      end

      # `options` 包含了转换器、验证器、文档、选项。
      #
      # 由于本对象可继承，基于不同的继承可分别表示基本类型、对象和数组，所以该属
      # 性可用在不同类型的对象上。需要时刻留意的是，无论是用在哪种类型的对象内，
      # `options` 属性都是描述该对象的本身，而不是深层的属性。
      #
      # 较常出现错误的是数组，`options` 是描述数组的，而不是描述数组内部元素的。
      attr_reader :options

      def initialize(options = {})
        options = OPTIONS_CHECKER.check(options)
        raise '不允许 BaseSchema 直接接受 array 类型，必须通过继承使用 ArraySchema' if options[:type] == 'array' && self.class == BaseSchema

        @options = SchemaOptions.normalize(options).freeze
      end

      USER_OPTIONS_CHECKER = Utils::KeywordArgs::Builder.build do
        key :execution, :object_value, :type_conversion, :validation, :user_data
        key :stage, validator: ->(value) { raise ArgumentError, "stage 只能取值为 :param 或 :render" unless [:param, :render].include?(value) }

        # 以下是 ObjectSchema 需要的选项
        # extra_properties 只能取值为 :ignore、:raise_error
        key :discard_missing, :extra_properties, :exclude, :scope
      end

      def filter(value, user_options = {})
        user_options = USER_OPTIONS_CHECKER.check(user_options)

        value = value_callback(user_options) if options[:value]
        value = before_callback(value, user_options) if options[:before]
        value = JsonSchema::Presenters.present(options[:presenter], value) if options[:presenter]
        value = resolve_default_value(options[:default]) if value.nil? && options.key?(:default)
        value = options[:convert].call(value) if options[:convert]

        # 第一步，转化值。
        # 需要注意的是，对象也可能被转换，因为并没有深层次的结构被声明。
        type = options[:type]
        unless user_options[:type_conversion] == false || type.nil? || value.nil?
          begin
            value = JsonSchema::TypeConverter.convert_value(value, type)
          rescue JsonSchema::TypeConvertError => e
            raise JsonSchema::ValidationError.new(e.message)
          end
        end

        # 第二步，做校验。
        validate!(value, options) unless user_options[:validation] == false

        # 第三步，如果存在内部属性，递归调用。
        value = filter_inner_elements(value, user_options) unless value.nil?

        # 最后，返回 value
        value = after_callback(value, user_options) if options[:after]
        value
      end

      def value?
        options[:value] != nil
      end

      # 生成 Swagger 文档的 schema 格式。
      #
      # 选项：
      # - stage: 传递 :param 或 :render
      # - schemas: 用于保存已经生成的 Schema
      # - presenter: 兼容 Grape 框架的实体类
      def to_schema_doc(**user_options)
        return Presenters.to_schema_doc(options[:presenter], options) if options[:presenter]

        schema = {}
        schema[:type] = options[:type] if options[:type]
        schema[:description] = options[:description] if options[:description]
        schema[:enum] = options[:allowable] if options[:allowable]

        schema
      end

      def to_schema
        self
      end

      private

      def validate!(value, stage_options)
        stage_options.each do |key, option|
          validator = JsonSchema::Validators[key]
          validator&.call(value, option, stage_options)
        end
      end

      def resolve_value(value, user_options, value_proc, arguments)
        if value_proc.lambda?
          value_proc_params = arguments[0...value_proc.arity]
        else
          value_proc_params = arguments
        end
        if user_options[:execution]
          user_options[:execution].instance_exec(*value_proc_params, &value_proc)
        else
          value_proc.call(*value_proc_params)
        end
      end

      def resolve_default_value(default_resolver)
        if default_resolver.respond_to?(:call)
          default_resolver.call
        elsif default_resolver.respond_to?(:dup)
          default_resolver.dup
        else
          default_resolver
        end
      end

      def filter_inner_elements(value, user_options)
        value
      end

      def before_callback(value, user_options)
        resolve_value(value, user_options, options[:before], [value, user_options[:object_value], user_options[:user_data]])
      end

      def after_callback(value, user_options)
        resolve_value(value, user_options, options[:after], [value, user_options[:object_value], user_options[:user_data]])
      end

      def value_callback(user_options)
        resolve_value(nil, user_options, options[:value], [user_options[:object_value], user_options[:user_data]])
      end
    end
  end
end
