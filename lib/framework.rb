require_relative 'route'

class Framework
  attr_reader :routes

  def initialize
    @routes = {}
  end

  def call(env)
    path = env['PATH_INFO']
    method = env['REQUEST_METHOD']

    route = routes[[path, method]]
    begin
      execution = route.call(env)
      response = execution.response
      [response.status, response.headers, [response.body]]
    rescue => e
      if e.message =~ /^status: (\d+)$/
        status = $1
        [status, { 'Content-Type' => 'text/html' }, ['Error!']]
      else
        raise e
      end
    end
  end

  def route(path, method)
    method = method.to_s.upcase
    routes[[path, method]] = Route.new
  end
end
