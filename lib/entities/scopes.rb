# frozen_string_literal: true

# 定义三个类型的 ParamScope：
#
#   - ObjectScope
#   - ArrayScope
#   - PrimitiveScope

require_relative 'type_converter'
require_relative 'validators'

module Entities
  class ObjectScope
    attr_reader :properties, :validations, :options

    def initialize(properties = {}, validations = {}, options = {})
      @properties = properties
      @validations = validations
      @options = options
    end

    def filter(params, path = '', execution = nil)
      params = execution.instance_exec(&@options[:value]) if @options[:value]
      return nil if params.nil?
      raise Errors::ParameterInvalid, '参数应该传递一个对象' unless params.is_a?(Hash)

      # 在解析参数前先对整体参数进行验证
      @validations.each do |type, names|
        validator = ObjectScope::Validators[type]
        validator.call(params, names, path)
      end

      # 递归解析参数
      @properties.map do |name, scope|
        p = path.empty? ? name : "#{path}.#{name}"
        [name, scope.filter(params[name.to_s], p, execution)]
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
      properties = @properties.filter { |name, scope|
        scope.options[:in].nil? || scope.options[:in] == 'body' 
      }.transform_values do |scope|
        scope.to_schema
      end

      if properties.empty?
        nil
      else
        schema = {
          type: 'object',
          properties: properties,
        }
        schema[:description] = options[:description] if options[:description]
        schema
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
    attr_reader :items, :options

    def initialize(items, options = {})
      @items = items
      @options = options
    end

    def filter(array_params, path, execution = nil)
      array_params = execution.instance_exec(&@options[:value]) if @options[:value]
      return nil if array_params.nil?
      raise Errors::ParameterInvalid, '参数应该传递一个数组' unless array_params.is_a?(Array)

      array_params.each_with_index.map do |item, index|
        p = "#{path}[#{index}]"
        @items.filter(item, p, execution)
      end
    end

    def to_schema
      schema = {
        type: 'array',
        items: @items ? @items.to_schema : {}
      }
      schema[:description] = options[:description] if options[:description]
      schema
    end
  end

  class PrimitiveScope
    attr_reader :options

    # 传递 path 参数主要是为了渲染 Parameter 文档时需要
    def initialize(options = {}, path = nil)
      @options = options
      @path = path
    end

    def filter(value, path, execution = nil)
      value = execution.instance_exec(&@options[:value]) if @options[:value]
      value = @options[:default] if value.nil? && @options[:default]
      value = @options[:transform].call(value) if @options[:transform]
      value = TypeConverter.convert_value(path, value, @options[:type]) if @options.key?(:type) && !value.nil?

      validate(value, options, path)

      value
    end

    def to_schema
      schema = {}
      schema[:type] = @options[:type] if @options[:type]
      schema[:description] = @options[:description] if @options[:description]

      schema
    end

    # 生成 Swagger 的参数文档，这个文档不同于 Schema，它主要存在于 Header、Path、Query 这些部分
    def generate_parameter_doc
      {
        name: @path,
        in: options[:in],
        type: options[:type],
        required: options[:required] || false,
        description: options[:description] || ''
      }
    end

    private

    def validate(value, options, path)
      # options 的每一个键都有可能是一个参数验证
      options.each do |key, option|
        validator = Validators[key]
        validator.call(value, option, path) if validator
      end
    end
  end
end
