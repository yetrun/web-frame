# frozen_string_literal: true

require 'rack'

class Execution
  attr_reader :request, :response

  def initialize(request)
    @request = request
    @response = Rack::Response.new
  end

  def render(value, options = {})
    @render = { value: value, options: options }
  end

  class Abort < StandardError
  end
end
