# frozen_string_literal: true

require_relative '../../utils/kwargs/check'
require_relative '../support/schema_options'

module Meta
  module JsonSchema
    class BaseSchema
      # `options` 包含了转换器、验证器、文档、选项。
      #
      # 由于本对象可继承，基于不同的继承可分别表示基本类型、对象和数组，所以该属
      # 性可用在不同类型的对象上。需要时刻留意的是，无论是用在哪种类型的对象内，
      # `options` 属性都是描述该对象的本身，而不是深层的属性。
      #
      # 较常出现错误的是数组，`options` 是描述数组的，而不是描述数组内部元素的。
      attr_reader :options

      def initialize(options = {})
        @options = SchemaOptions.normalize(options)
      end

      USER_OPTIONS_CHECKER = Utils::KeywordArgs::Builder.build do
        key :stage, :execution, :object_value, :type_conversion, :validation

        # 以下三个是 ObjectSchema 需要的选项
        key :discard_missing, :exclude, :scope
      end

      def filter(value, user_options = {})
        user_options = USER_OPTIONS_CHECKER.check(user_options)

        value = resolve_value(user_options) if options[:value]
        value = JsonSchema::Presenters.present(options[:presenter], value) if options[:presenter]
        value = options[:default] if value.nil? && options.key?(:default)
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

        value
      end

      def value?
        options[:value] != nil
      end

      def resolve_value(user_options)
        value_proc = options[:value]
        value_proc_params = (value_proc.lambda? && value_proc.arity == 0) ?  [] : [user_options[:object_value]]

        if user_options[:execution]
          user_options[:execution].instance_exec(*value_proc_params, &value_proc)
        else
          value_proc.call(*value_proc_params)
        end
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
    end
  end
end
