# frozen_string_literal: true

require 'rack'

class Execution
  attr_reader :request, :response

  def initialize(request)
    @request = request
    @response = Rack::Response.new
  end

  class Abort < StandardError
  end
end
