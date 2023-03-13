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
      attr_reader :param_options, :render_options

      def initialize(options = {})
        @param_options, @render_options = SchemaOptions.normalize_to_param_and_render(options)
      end

      def options(stage, key = nil)
        stage_options = case stage 
                        when :param 
                          param_options
                        when :render
                          render_options
                        when nil
                          merged_options
                        else
                          raise "非法的 stage 参数，它只允许取值 :param、:render 或 nil，却收到 #{stage.inspect}"
                        end
        if key
          stage_options ? stage_options[key] : nil
        else
          stage_options
        end
      end

      # 将 params 和 render 的选项合并
      def merged_options
        (param_options || {}).merge(render_options || {})
      end

      def filter(value, user_options = {})
        user_options = Utils::KeywordArgs.check(
          args: user_options,
          schema: {
            stage: nil,
            execution: nil,
            object_value: nil,
            type_conversion: true,
            validation: true,

            # 以下三个是 ObjectSchema 需要的选项
            discard_missing: false,
            exclude: [],
            scope: []
          }
        )

        stage_options = options(user_options[:stage])

        value = resolve_value(user_options) if stage_options[:value]
        value = JsonSchema::Presenters.present(stage_options[:presenter], value) if stage_options[:presenter]
        value = stage_options[:default] if value.nil? && stage_options.key?(:default)
        value = stage_options[:convert].call(value) if stage_options[:convert]

        # 第一步，转化值。
        # 需要注意的是，对象也可能被转换，因为并没有深层次的结构被声明。
        type = stage_options[:type]
        unless user_options[:type_conversion] == false || type.nil? || value.nil?
          begin
            value = JsonSchema::TypeConverter.convert_value(value, type)
          rescue JsonSchema::TypeConvertError => e
            raise JsonSchema::ValidationError.new(e.message)
          end
        end

        # 第二步，做校验。
        validate!(value, stage_options) unless user_options[:validation] == false

        # 第三步，如果使用了 using 块，需要进一步解析
        if stage_options[:using] && stage_options[:using].is_a?(Hash)
          schema = stage_options[:using][:resolve].call(value).to_schema
          value = schema.filter(value, user_options)
        end

        value
      end

      def value?(stage)
        options(stage, :value) != nil
      end

      def resolve_value(user_options)
        value_proc = options(user_options[:stage], :value)
        value_proc_params = (value_proc.lambda? && value_proc.arity == 0) ?  [] : [user_options[:object_value]]

        if user_options[:execution]
          user_options[:execution].instance_exec(*value_proc_params, &value_proc)
        else
          value_proc.call(*value_proc_params)
        end
      end

      def to_schema_doc(user_options = {})
        stage_options = options(user_options[:stage])

        return Presenters.to_schema_doc(stage_options[:presenter], stage_options) if stage_options[:presenter]

        schema = {}
        schema[:type] = stage_options[:type] if stage_options[:type]
        schema[:description] = stage_options[:description] if stage_options[:description]
        schema[:enum] = stage_options[:allowable] if stage_options[:allowable]
        if stage_options[:using] && stage_options[:using].is_a?(Hash)
          using_options = stage_options[:using]
          schema[:oneOf] = using_options[:one_of].map do |schema|
            schema.to_schema.to_schema_doc(user_options)
          end if using_options[:one_of]
        end

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
