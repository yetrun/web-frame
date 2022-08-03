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
      def initialize(options = {})
        options = options.dup
        param_options = options.delete(:param) # true、false 或者 Hash
        render_options = options.delete(:render) # true、false 或者 Hash
        param_options = {} if param_options.nil? || param_options == true
        render_options = {} if render_options.nil? || render_options == true

        @param_options = param_options ? options.merge(param_options) : false
        @render_options = render_options ? options.merge(render_options) : false
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
        scope_options = user_options[:stage] == :param ? @param_options : @render_options

        value = resolve_value(user_options) if scope_options[:value]
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

      def value?(stage)
        options(stage, :value) != nil
      end

      def resolve_value(user_options)
        scope_options = user_options[:stage] == :param ? @param_options : @render_options

        value_proc = scope_options[:value]
        value_proc_params = (value_proc.lambda? && value_proc.arity == 0) ?  [] : [user_options[:object_value]]

        if user_options[:execution]
          user_options[:execution].instance_exec(*value_proc_params, &value_proc)
        else
          value_proc.call(*value_proc_params)
        end
      end

      def to_schema_doc(user_options = {})
        stage_options = user_options[:stage] == :param ? @param_options : @render_options

        return Presenters.to_schema_doc(stage_options[:presenter], stage_options) if stage_options[:presenter]

        schema = {}
        schema[:type] = stage_options[:type] if stage_options[:type]
        schema[:description] = stage_options[:description] if stage_options[:description]

        schema
      end

      def to_schema
        self
      end

      private

      def validate!(value, user_options)
        # TODO: 就一点： 如果将来添加新的选项，都要在这里添加，很烦
        discarding_options = %i[type desc value using default presenter convert scope]
        registered_validators = JsonSchema::Validators.keys + discarding_options
        unknown_validators = user_options.keys - registered_validators
        raise "未知的选项：#{unknown_validators.join(', ')}" unless unknown_validators.empty?

        user_options.each do |key, option|
          validator = JsonSchema::Validators[key]
          validator&.call(value, option, user_options)
        end
      end
    end
  end
end
