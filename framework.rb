class Framework
  attr_reader :routes

  def initialize
    @routes = {}
  end

  def call(env)
    path = env['PATH_INFO']
    route = routes[path]
    route.call

    ['200', { 'Content-Type' => 'text/html' }, ['Hello, Framework!']]
  end

  def path(path)
    routes[path] = Route.new
  end
end

class Route
  def do_any(&block)
    @block = block
  end

  def call
    @block.call
  end
end
