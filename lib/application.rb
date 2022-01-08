# frozen_string_literal: true

require_relative 'route'

class Application
  class << self
    attr_reader :routes

    def inherited(mod)
      super

      mod.class_eval { @routes = [] }
    end

    def call(env)
      request = Rack::Request.new(env)

      route = matched_route(request)
      raise Errors::NoMatchingRouteError, "未能发现匹配的路由：#{request.request_method} #{request.path}" unless route

      route.call(request)
    end

    def route(path, method)
      route = Route.new(path, method)
      routes << route
      route
    end

    def apply(mod)
      @routes.concat(mod.routes)
    end

    private

    def matched_route(request)
      routes.find { |route| route.match?(request) }
    end
  end
end
