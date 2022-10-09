# frozen_string_literal: true

require 'rack'

module Dain
  class Execution
    attr_reader :request, :response

    def initialize(request)
      @request = request
      @response = Rack::Response.new
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
