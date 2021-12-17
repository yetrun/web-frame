require_relative 'route'

class App
  attr_reader :routes

  def initialize
    @routes = {}
  end

  def call(env)
    path = env['PATH_INFO']
    method = env['REQUEST_METHOD']

    route = routes[[path, method]]
    output = route.call

    ['200', { 'Content-Type' => 'text/html' }, ['Hello, app!']] unless output && output.is_a?(Array)
  end

  def route(path, method)
    method = method.to_s.upcase
    routes[[path, method]] = Route.new
  end
end
