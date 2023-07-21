# frozen_string_literal: true

require 'rack'

module Meta
  class Execution
    attr_reader :request, :response
    attr_accessor :route_meta

    def initialize(request)
      @request = request
      @response = Rack::Response.new([], 0) # 状态码初始为 0，代表一个未设置状态
      @parameters = {}
    end

    def parameters
      @_parameters || @_parameters = route_meta.parse_parameters(self)
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
        @_request_body[:keep_missing] || @_request_body[:keep_missing] = route_meta.parse_request_body(self).freeze
      when :discard_missing
        @_request_body[:discard_missing] || @_request_body[:discard_missing] = route_meta.parse_request_body(self, discard_missing: true).freeze
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
        params = params.merge(request_body(mode) || {}) if route_meta.request_body
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

        new_hash = route_meta.render_entity(self, entity_schema, hash, options)
        response.content_type = 'application/json' if response.content_type.nil?
        response.body = [JSON.generate(new_hash)]
      else
        # 渲染多键值结点
        errors = {}
        final_value = {}
        renders.each do |key, render_content|
          raise Errors::RenderingError, "渲染的键名 `#{key}` 不存在，请检查实体定义以确认是否有拼写错误" unless entity_schema.properties.key?(key)
          schema = entity_schema.properties[key].staged(:render)
          final_value[key] = route_meta.render_entity(self, schema, render_content[:value], render_content[:options])
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
