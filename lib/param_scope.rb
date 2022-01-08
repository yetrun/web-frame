# frozen_string_literal: true

require_relative 'param_checker'

class SingleParamScope
  def initialize(name, options={}, &block)
    @name = name.to_sym
    @options = options

    if block_given?
      @inner_scope = options[:type] == Array ? ArrayParamScope.new(&block) : HashParamScope.new(&block)
    end
  end

  def filter(params)
    value = params[@name.to_s] || @options[:default]
    value = ParamChecker.convert_type(@name, value, @options[:type]) if @options.key?(:type) && !value.nil?

    # 经过 @inner_scope 的洗礼
    value = @inner_scope.filter(value) if @inner_scope && !value.nil?

    # 在经过一系列的检查
    ParamChecker.check_required(@name, value, @options[:required]) if @options.key?(:required)

    { @name => value }
  end
end

class HashParamScope
  def initialize(&block)
    @scopes = []

    self.instance_eval &block
  end

  def param(name, options={}, &block)
    name = name.to_s

    @scopes << SingleParamScope.new(name, options, &block)
  end

  def filter(params)
    value = {}

    @scopes.each do |scope|
      value.merge!(scope.filter(params))
    end

    value
  end
end

class ArrayParamScope
  def initialize(&block)
    @inner_scope  = HashParamScope.new(&block) if block_given?
  end

  def filter(params)
    params.map do |item|
      @inner_scope.filter(item)
    end
  end
end
