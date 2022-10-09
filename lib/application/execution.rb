# frozen_string_literal: true

require 'rack'

module Dain
  class Execution
    attr_reader :request, :response, :params_schema

    def initialize(request)
      @request = request
      @response = Rack::Response.new
    end

    # 调用方式：
    #
    # - params
    # - params(:discard_missing)
    # - params(:raw)
    def params(mode = nil)
      case mode
      when :raw
        @_raw_params || @_raw_params = parse_raw_params.freeze
      when :discard_missing
        @_modified_params || @_modified_params = parse_modified_params.freeze
      else
        @_replaced_params || @_replaced_params = parse_replaced_params.freeze
      end
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

    def parse_params(params_schema)
      @params_schema = params_schema

      # 清理来自父路由的参数
      remove_instance_variable(:@_raw_params) if instance_variable_defined?(:@_raw_params)
      remove_instance_variable(:@_modified_params) if instance_variable_defined?(:@_modified_params)
      remove_instance_variable(:@_replaced_params) if instance_variable_defined?(:@_replaced_params)

      # 激活一遍 params
      params
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

        begin
          new_hash = entity_schema.filter(hash, **options, execution: self, stage: :render)
        rescue JsonSchema::ValidationErrors => e
          raise Errors::RenderingInvalid.new(e.errors)
        end
        response.body = [JSON.generate(new_hash)]
      else
        # 渲染多键值结点
        new_hash = renders.map do |key, render_content|
          schema = entity_schema.properties[key]
          raise Errors::RenderingError, "渲染的键名 `#{key}` 不存在，请检查实体定义以确认是否有拼写错误" if schema.nil?

          [key, schema.filter(render_content[:value], render_content[:options])]
        end.to_h
        response.body = [JSON.generate(new_hash)]
      end
    end

    private

    def parse_raw_params
      request_body = request.body.read
      json = request_body.empty? ? {} : JSON.parse(request_body)
      json.merge!(request.params) if json.is_a?(Hash) # TODO: 如果参数模式不是对象，就无法合并 query 和 path 里的参数

      request.body.rewind
      json
    end

    def parse_modified_params
      begin
        params_schema.filter(params(:raw), stage: :param, discard_missing: true)
      rescue JsonSchema::ValidationErrors => e
        raise Errors::ParameterInvalid.new(e.errors)
      end
    end

    def parse_replaced_params
      begin
        params_schema.filter(params(:raw), stage: :param)
      rescue JsonSchema::ValidationErrors => e
        raise Errors::ParameterInvalid.new(e.errors)
      end
    end

    class Abort < StandardError
    end

    # 使得能够处理 Execution 的类作为 Rack 中间件
    module MakeToRackMiddleware
      def call(env)
        # 初始化一个执行环境
        request = Rack::Request.new(env)
        execution = Execution.new(request)

        execute(execution)

        response = execution.response
        response.content_type = 'application/json' unless response.no_content?
        response.to_a
      end
    end
  end
end
