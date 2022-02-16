# frozen_string_literal: true

# 定义三个类型的 ParamScope：
#
#   - ObjectScope
#   - ArrayScope
#   - PrimitiveScope

require_relative 'checker'
require_relative 'validators'

module Params
  class ObjectScope
    def initialize(&block)
      @properties = {}
      @required = []
      @validations = {}

      instance_eval(&block)
    end

    # 当且仅当 ObjectScope 提供了 `param` 方法
    def param(name, options = {}, &block)
      name = name.to_sym

      if options[:is_array]
        @properties[name] = ArrayScope.new(options, &block)
      elsif block_given?
        @properties[name] = ObjectScope.new(&block) # TODO: options 怎么办？
      else
        @properties[name] = PrimitiveScope.new(options)
      end
    end

    def validates(type, names)
      @validations[type] = names
    end

    def filter(params)
      return nil if params.nil?
      raise Errors::ParameterInvalid, '参数应该传递一个对象' unless params.is_a?(Hash)

      # 在解析参数前先对整体参数进行验证
      @validations.each do |type, names|
        validator = Params::ObjectScope::Validators[type]
        validator.call(params, names)
      end

      # 递归解析参数
      @properties.map do |name, scope|
        [name, scope.filter(params[name.to_s])]
      end.to_h
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
      scopes = @properties.values.filter { |scope| scope.options[:in].nil? || scope.options[:in] == 'body' }

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
      scopes = @properties.values.filter { |scope| scope.options[:in] && scope.options[:in] != 'body' }

      scopes.map do |scope|
        scope.generate_parameter_doc
      end
    end
  end

  class ArrayScope
    def initialize(options, &block)
      if block_given?
        @items  = ObjectScope.new(&block) # TODO: options 怎么办？
      else
        @items = PrimitiveScope.new(options)
      end
    end

    def filter(array_params)
      return nil if array_params.nil?
      raise Errors::ParameterInvalid, '参数应该传递一个数组' unless array_params.is_a?(Array)

      array_params.map do |item|
        @items.filter(item)
      end
    end

    def to_schema
      {
        type: 'array',
        items: @items ? @items.to_schema : {}
      }
    end
  end

  class PrimitiveScope
    attr_reader :options

    def initialize(options = {})
      @options = options
    end

    def filter(value)
      value = value || @options[:default]
      value = ParamChecker.convert_type('some param', value, @options[:type]) if @options.key?(:type) && !value.nil?

      # 验证参数
      validate(value, options)

      value
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

    private

    def validate(value, options)
      # options 的每一个键都有可能是一个参数验证
      options.each do |key, option|
        validator = Validators[key]
        validator.call(value, option) if validator
      end
    end
  end
end
