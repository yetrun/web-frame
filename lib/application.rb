require_relative 'route'

class Application
  def self.inherited(mod)
    mod.class_eval { @routes = [] }
  end

  def self.routes
    @routes
  end

  def self.call(env)
    request = Rack::Request.new(env)

    route = matched_route(request)
    raise Errors::NoMatchingRouteError.new("未能发现匹配的路由：#{request.request_method} #{request.path}") unless route

    route.call(request)
  end

  def self.route(path, method)
    route = Route.new(path, method)
    routes << route
    route
  end

  def self.apply(mod)
    @routes = @routes.concat(mod.routes)
  end

  private

  def self.matched_route(request)
    routes.find { |route| route.match?(request) }
  end
end
