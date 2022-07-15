# frozen_string_literal: true

module Dain
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

      # 传递 path 参数主要是为了渲染 Parameter 文档时需要
      def initialize(options = {}, path = nil)
        options = options.dup
        param_options = options.delete(:param) # true、false 或者 Hash
        render_options = options.delete(:render) # true、false 或者 Hash
        param_options = {} if param_options.nil? || param_options == true
        render_options = {} if render_options.nil? || render_options == true

        @param_options = param_options ? options.merge(param_options) : false
        @render_options = render_options ? options.merge(render_options) : false

        @path = path
      end

      def options
        param_options.merge(render_options)
      end

      def filter(value, options = {})
        execution = options[:execution]
        scope_options = options[:stage] == :param ? @param_options : @render_options

        value = execution.instance_exec(&scope_options[:value]) if scope_options[:value]
        # value = scope_options[:presenter].represent(value).as_json if scope_options[:presenter]
        value = JsonSchema::Presenters.present(scope_options[:presenter], value) if scope_options[:presenter]
        value = scope_options[:default] if value.nil? && scope_options[:default]
        value = scope_options[:convert].call(value) if scope_options[:convert]
        # 这一步转换值。需要注意的是，对象也可能被转换，因为并没有深层次的结构被声明。
        if scope_options.key?(:type) && !value.nil?
          begin
            value = JsonSchema::TypeConverter.convert_value(value, scope_options[:type])
          rescue JsonSchema::TypeConvertError => e
            raise JsonSchema::ValidationError.new(e.message)
          end
        end

        validate!(value, scope_options)

        value
      end

      # stage 取值为 :param、:render 或 nil
      def value?(stage)
        if stage.nil?
          options[:value] != nil
        elsif stage.to_sym == :param
          param_options[:value] != nil
        elsif stage.to_sym == :render
          render_options[:value] != nil
        else
          raise "非法的 stage 参数，它允许的取值范围是 :param、:render 和 nil，实际却收获到 #{stage.inspect}"
        end
      end

      def to_schema_doc(options = {})
        scope_options = options[:stage] == :param ? @param_options : @render_options

        return Presenters.to_schema_doc(scope_options[:presenter], scope_options) if scope_options[:presenter]

        schema = {}
        schema[:type] = scope_options[:type] if scope_options[:type]
        schema[:description] = scope_options[:description] if scope_options[:description]

        schema
      end

      # 生成 Swagger 的参数文档，这个文档不同于 Schema，它主要存在于 Header、Path、Query 这些部分
      def generate_parameter_doc(options = {})
        scope_options = options[:stage] == :param ? @param_options : @render_options

        {
          name: @path,
          in: scope_options[:in],
          type: scope_options[:type],
          required: scope_options[:required] || false,
          description: scope_options[:description] || ''
        }
      end

      def to_schema
        self
      end

      private

      def validate!(value, options)
        # TODO: 就一点： 如果将来添加新的选项，都要在这里添加，很烦
        discarding_options = %i[type desc value using default presenter convert scope]
        registered_validators = JsonSchema::Validators.keys + discarding_options
        unknown_validators = options.keys - registered_validators
        raise "未知的选项：#{unknown_validators.join(', ')}" unless unknown_validators.empty?

        options.each do |key, option|
          validator = JsonSchema::Validators[key]
          validator&.call(value, option, options)
        end
      end
    end
  end
end
