require_relative 'route'

class Application
  def self.inherited(subclass)
    subclass.class_eval { @routes = {} }
  end

  def self.routes
    @routes
  end

  def self.call(env)
    path = env['PATH_INFO']
    method = env['REQUEST_METHOD']

    route_key, route = match_route(path, method)
    raise Errors::NoMatchingRouteError.new("未能发现匹配的路由：#{method} #{path}") unless route

    path_params = route_key[0].match(path).named_captures
    execution = route.call(env, path_params)

    response = execution.response
    [response.status, response.headers, [response.body]]
  end

  def self.route(path, method)
    path_regex = path.gsub(/:(\w+)/) { "(?<#{$1}>[^/]+)" }
    path_regex = Regexp.new('^' + path_regex + '$')

    method = method.to_s.upcase
    routes[[path_regex, method]] = Route.new
  end

  def self.apply(mod)
    @routes.merge!(mod.routes)
  end

  private

  def self.match_route(path, method)
    route_key, route = routes.find { |route_key, value| 
      route_path, route_method = route_key

      route_path.match(path) && route_method == method
    }

    return [route_key, route]
  end
end
