# frozen_string_literal: true

require_relative 'param_checker'

class SingleParamScope
  attr_reader :name, :options

  def initialize(name, options = {}, &block)
    @name = name.to_sym
    @options = options

    if block_given?
      @inner_scope = options[:type] == 'array' ? ArrayParamScope.new(&block) : HashParamScope.new(&block)
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

  def to_schema
    if @inner_scope
      schema = @inner_scope.to_schema
    else
      schema = {}
      schema[:type] = @options[:type] if @options[:type]
    end

    schema[:description] = @options[:description] if @options[:description]

    schema
  end

  def generate_parameter_doc
    {
      name: name,
      in: options[:in],
      type: options[:type],
      required: options[:required] || false,
      description: options[:description] || ''
    }
  end
end

class HashParamScope
  def initialize(&block)
    @single_param_scopes = []

    instance_eval(&block)
  end

  def param(name, options = {}, &block)
    name = name.to_s

    @single_param_scopes << SingleParamScope.new(name, options, &block)
  end

  def filter(params)
    value = {}

    @single_param_scopes.each do |scope|
      value.merge!(scope.filter(params))
    end

    value
  end

  # 生成 Swagger 文档的 schema 格式，所谓 schema 格式，是指形如
  #
  #     {
  #       type: 'object',
  #       properties: {
  #         ...
  #       }
  #     }
  #
  # 的格式。
  def to_schema
    # 提取根路径的所有 `:in` 选项为 `body` 的元素（默认值为 `body`）
    scopes = @single_param_scopes.filter { |scope| scope.options[:in].nil? || scope.options[:in] == 'body' }
    
    properties = scopes.map do |scope|
      [scope.name, scope.to_schema]
    end.to_h

    if properties.empty?
      nil
    else
      {
        type: 'object',
        properties: properties
      }
    end
  end

  # 生成 Swagger 文档的 parameters 部分，这里是指生成路径位于 `path`、`query`
  # 的参数
  def generate_parameters_doc
    # 提取根路径的所有 `:in` 选项不为 `body` 的元素（默认值为 `body`）
    scopes = @single_param_scopes.filter { |scope| scope.options[:in] && scope.options[:in] != 'body' }

    scopes.map do |scope|
      scope.generate_parameter_doc
    end
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

  def to_schema
    {
      type: 'array',
      items: @inner_scope ? @inner_scope.to_schema : {}
    }
  end
end
