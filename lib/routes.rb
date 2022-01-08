# frozen_string_literal: true

require_relative 'route'

class Routes
  attr_reader :routes

  def initialize
    @routes = []
  end

  def execute(execution)
    route = matched_route(execution.request)
    route.execute(execution)
  end

  def route(path, method)
    route = Route.new(path, method)
    routes << route
    route
  end

  def match?(execution)
    matched_route(execution.request) != nil
  end

  private

  def matched_route(request)
    routes.find { |route| route.match?(request) }
  end
end
