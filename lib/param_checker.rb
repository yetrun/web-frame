require_relative 'errors'

module ParamChecker
  @string_converters = {
    Integer => ->(name, value) { 
      raise Errors::ParameterInvalid.new("参数 `#{name}` 类型错误") unless value =~ /^[+-]?\d+$/

      value.to_i
    }
  }.freeze

  def self.convert_type(name, value, type)
    return nil if value.nil?
    return convert_string_to_type(name, value, type) if value.is_a?(String) && type != String

    # 默认情况下需要类型匹配
    raise Errors::ParameterInvalid.new("参数 `#{name}` 类型错误") unless value.is_a?(type)

    value
  end

  def self.check_required(name, value, required)
    raise Errors::ParameterInvalid.new("参数 `#{name}` 为必选项") if required && value.nil?
  end

  private

  # value is string, but type is not string
  def self.convert_string_to_type(name, value, type)
    if @string_converters.key?(type)
      @string_converters[type].call(name, value)
    else
      raise Errors::ParameterInvalid.new("参数 `#{name}` 类型错误")
    end
  end
end
