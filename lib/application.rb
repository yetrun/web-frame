# frozen_string_literal: true

require_relative 'routes'

class Application
  class << self
    attr_reader :applications, :routes, :before_callbacks, :after_callbacks

    def inherited(mod)
      super

      mod.class_eval {
        @applications = []
        @routes = Routes.new
        @before_callbacks = []
        @after_callbacks = []
        @error_guards = []
      }
    end

    def call(env)
      # 初始化一个执行环境
      request = Rack::Request.new(env)
      execution = Execution.new(request)

      if match?(execution)
        execute(execution)
      else
        raise Errors::NoMatchingRoute, "未能发现匹配的路由：#{request.request_method} #{request.path}"
      end

      execution.response.to_a
    end

    def execute(execution)
      before_callbacks.each { |b| execution.instance_eval(&b) }

      if routes.match?(execution)
        routes.execute(execution)
      else
        application = applications.find { |app| app.match?(execution) }
        application.execute(execution)
      end

      after_callbacks.each { |b| execution.instance_eval(&b) }
    rescue => error
      raise unless guard = @error_guards.find { |guard| error.is_a?(guard[:error_class]) }

      execution.instance_eval(&guard[:caller])
    end

    def match?(execution)
      return true if routes.match?(execution)

      applications.any? { |app| app.match?(execution) }
    end

    def route(path, method)
      routes.route(path, method)
    end

    def before(&block)
      before_callbacks << block
    end

    def after(&block)
      after_callbacks << block
    end
    
    def rescue_error(error_class, &block)
      @error_guards << { error_class: error_class, caller: block }
    end

    def apply(mod)
      applications << mod
    end
  end
end
