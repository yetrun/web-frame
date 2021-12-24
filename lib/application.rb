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

    # TODO: 404 没处理
    route = routes[[path, method]]
    execution = route.call(env)
    response = execution.response
    [response.status, response.headers, [response.body]]
  end

  def self.route(path, method)
    method = method.to_s.upcase
    routes[[path, method]] = Route.new
  end
end
