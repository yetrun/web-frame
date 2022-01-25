# frozen_string_literal: true

require_relative 'errors'

module ParamChecker
  @types = {
    'boolean' => {
      string_converter: ->(name, value) {
        raise Errors::ParameterInvalid, "参数 `#{name}` 类型错误" unless ['true', 'false'].include?(value.downcase)

        value == 'true'
      },
      class_matcher: [TrueClass, FalseClass]
    },
    'integer' => {
      string_converter: ->(name, value) {
        raise Errors::ParameterInvalid, "参数 `#{name}` 类型错误" unless value =~ /^[+-]?\d+$/

        value.to_i
      },
      class_matcher: [Integer]
    },
    'number' => {
      string_converter: ->(name, value) {
        raise Errors::ParameterInvalid, "参数 `#{name}` 类型错误" unless value =~ /^[+-]?\d+(\.\d+)?$/

        value.to_f
      },
      class_matcher: [Numeric]
    },
    'string' => {
      string_converter: ->(name, value) { value },
      class_matcher: [String]
    },
    'object' => {
      class_matcher: [Hash]
    },
    'array' => {
      class_matcher: [Array]
    }
  }

  class << self
    def convert_type(name, value, type)
      return nil if value.nil?
      return convert_string_value_to_specific_type(name, value, type) if value.is_a?(String) && type != 'string'

      # 默认情况下需要类型匹配
      raise Errors::ParameterInvalid, "参数 `#{name}` 类型错误" unless match_type?(value, type)

      value
    end

    def check_required(name, value, required)
      raise Errors::ParameterInvalid, "参数 `#{name}` 为必选项" if required && value.nil?
    end

    private

    def convert_string_value_to_specific_type(name, value, type)
      raise Errors::ParameterInvalid, "参数 `#{name}` 类型错误" unless @types.key?(type) && @types[type].key?(:string_converter)

      @types[type][:string_converter].call(name, value)
    end

    def match_type?(value, type)
      raise "未知的类型：#{type}" unless @types.key?(type) && @types[type].key?(:class_matcher)

      @types[type][:class_matcher].any? { |klass| value.class <= klass }
    end
  end
end
