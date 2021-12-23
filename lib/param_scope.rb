require_relative 'param_checker'

class ParamScope
  def initialize(name, options={}, &block)
    @name = name.to_sym
    @options = options
  end

  def filter(params)
    value = params[@name.to_s] || @options[:default]

    ParamChecker.check_type(@name, value, @options[:type]) if @options.key?(:type)
    ParamChecker.check_required(@name, value, @options[:required]) if @options.key?(:required)

    { @name => value }
  end
end
