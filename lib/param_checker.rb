require_relative 'errors'

module ParamChecker
  def self.check_type(name, value, type)
    return if value.nil?

    raise Errors::ParameterInvalid.new("参数 `#{name}` 类型错误") unless value.is_a?(type)
  end

  def self.check_required(name, value, required)
    raise Errors::ParameterInvalid.new("参数 `#{name}` 为必选项") if required && value.nil?
  end
end
