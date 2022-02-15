# frozen_string_literal: true

# 定义三个类型的 ParamScope：
#
#   - ObjectScope
#   - ArrayScope
#   - PrimitiveScope

require_relative 'param_checker'

module ParamScope
  class PrimitiveScope
    attr_reader :options

    def initialize(options = {})
      @options = options
    end

    def filter(value)
      value = value || @options[:default]
      value = ParamChecker.convert_type('some param', value, @options[:type]) if @options.key?(:type) && !value.nil?

      # 经过 @inner_scope 的洗礼
      value = @inner_scope.filter(value) if @inner_scope && !value.nil?

      # 在经过一系列的检查
      ParamChecker.check_format(value, @options[:format]) if @options.key?(:format)

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
  end

  class ObjectScope
    def initialize(&block)
      @properties = {}
      @required = []

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

    # 声明哪些属性是 required 的
    def required(*names)
      @required = names
    end

    def filter(params)
      return nil if params.nil?
      raise Errors::ParameterInvalid, '参数应该传递一个对象' unless params.is_a?(Hash)
      
      missing_any = @required.any? do |name|
        params[name.to_s].nil? # 键不存在或值为 nil
      end
      raise Errors::ParameterInvalid, '有些必传参数没有传递' if missing_any

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
end
