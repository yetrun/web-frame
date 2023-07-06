# frozen_string_literal: true

require 'rack'

module Meta
  class Execution
    attr_reader :request, :response, :params_schema, :request_body_schema
    attr_accessor :parameters

    def initialize(request)
      @request = request
      @response = Rack::Response.new([], 0) # 状态码初始为 0，代表一个未设置状态
      @parameters = {}
    end

    # 调用方式：
    #
    # - `request_body`：等价于 request_body(:keep_missing)
    # - `request_body(:keep_missing)`
    # - `request_body(:discard_missing)`
    def request_body(mode = :keep_missing)
      @_request_body ||= {}

      case mode
      when :keep_missing
        @_request_body[:keep_missing] || @_request_body[:keep_missing] = parse_request_body_for_replacing.freeze
      when :discard_missing
        @_request_body[:discard_missing] || @_request_body[:discard_missing] = parse_request_body_for_updating.freeze
      else
        raise NameError, "未知的 mode 参数：#{mode}"
      end
    end

    # 调用方式：
    #
    # - `params`：等价于 params(:keep_missing)
    # - `params(:keep_missing)`
    # - `params(:discard_missing)`
    # - `params(:raw)`
    def params(mode = :keep_missing)
      @_params ||= {}
      return @_params[mode] if @_params.key?(mode)

      if mode == :raw
        @_params[:raw] = parse_raw_params.freeze
      else
        params = parameters
        params = params.merge(request_body(mode) || {}) if @request_body_schema
        @_params[mode] = params
      end

      @_params[mode]
    end

    # 调用方式：
    #
    # - render(value, options?)
    # - render(key, value, options?)
    def render(*params)
      if (params.length < 1 || params.length > 3)
        raise ArgumentError, "wrong number of arguments (given #{params.length} expected 1..3)"
      elsif params[0].is_a?(Symbol)
        key, value, options = params
      else
        key = :__root__
        value, options = params
      end

      @renders ||= {}
      @renders[key] = { value: value, options: options || {} }
    end

    # 运行过程中首先会解析参数
    def parse_parameters(parameters_meta)
      self.parameters = parameters_meta.filter(request).freeze
    end

    # parse_params 不再解析参数了，而只是设置 @params_schema，并清理父路由解析的变量
    def parse_params(params_schema)
      @params_schema = params_schema # TODO: 到底是用 @params_schema 还是 @request_body
    end

    def parse_request_body(schema)
      @request_body_schema = schema
    end

    def render_entity(entity_schema)
      # 首先获取 JSON 响应值
      renders = @renders || {}

      if renders.key?(:__root__) || renders.empty?
        # 从 root 角度获取
        if renders[:__root__]
          hash = renders[:__root__][:value]
          options = renders[:__root__][:options]
        else
          response_body = response.body ? response.body[0] : nil
          hash = response_body ? JSON.parse(response_body) : {}
          options = {}
        end

        new_hash = entity_schema.filter(hash,
          **options,
          execution: self,
          stage: :render,
          extra_properties: Meta.config.handle_extra_properties, # TODO: 导出渲染时的 user_options. 注意解析参数时不一样。我在想是不是添加一个 config.json_schema_user_options 完事？
          validation: Meta.config.render_validation,
          type_conversion: ::Meta.config.render_type_conversion
        )
        response.content_type = 'application/json' if response.content_type.nil?
        response.body = [JSON.generate(new_hash)]
      else
        # 渲染多键值结点
        errors = {}
        final_value = {}
        renders.each do |key, render_content|
          raise Errors::RenderingError, "渲染的键名 `#{key}` 不存在，请检查实体定义以确认是否有拼写错误" unless entity_schema.properties.key?(key)
          schema = entity_schema.properties[key].schema(:render)
          final_value[key] = schema.filter(render_content[:value], **render_content[:options], execution: self, stage: :render)
        rescue JsonSchema::ValidationErrors => e
          # 错误信息再度绑定 key
          errors.merge! e.errors.transform_keys! { |k| k.empty? ? key : "#{key}.#{k}" }
        end.to_h

        if errors.empty?
          response.content_type = 'application/json' if response.content_type.nil?
          response.body = [JSON.generate(final_value)]
        else
          raise Errors::RenderingInvalid.new(errors)
        end
      end
    rescue JsonSchema::ValidationErrors => e
      raise Errors::RenderingInvalid.new(e.errors)
    end

    def abort_execution!
      raise Abort
    end

    private

    def parse_raw_params
      request_body = request.body.read
      if request_body.empty?
        json = {}
      elsif !request.content_type.start_with?('application/json')
        raise Errors::UnsupportedContentType, "只接受 Content-Type 为 application/json 的请求参数，当前格式：#{request.content_type}"
      else
        json = JSON.parse(request_body)
      end
      json.merge!(request.params) if json.is_a?(Hash)

      request.body.rewind
      json
    end

    def parse_request_body_for_replacing
      request_body_schema.filter(params(:raw), execution: self, stage: :param, extra_properties: Meta.config.handle_extra_properties)
    rescue JsonSchema::ValidationErrors => e
      raise Errors::ParameterInvalid.new(e.errors)
    end

    def parse_request_body_for_updating
      request_body_schema.filter(params(:raw), execution: self, stage: :param, discard_missing: true, extra_properties: Meta.config.handle_extra_properties)
    rescue JsonSchema::ValidationErrors => e
      raise Errors::ParameterInvalid.new(e.errors)
    end

    class Abort < Exception
    end

    # 使得能够处理 Execution 的类作为 Rack 中间件
    module MakeToRackMiddleware
      def call(env)
        # 初始化一个执行环境
        request = Rack::Request.new(env)
        execution = Execution.new(request)

        execute(execution, request.path)

        response = execution.response
        response.to_a
      end
    end
  end
end
