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
        key = :root
        value, options = params
      end

      @renders ||= {}
      @renders[key] = { value: value, options: options || {} }
    end

    class Abort < StandardError
    end
  end
end
