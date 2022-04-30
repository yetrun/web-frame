# frozen_string_literal: true

require 'rack'

class Execution
  attr_reader :request, :response

  def initialize(request)
    @request = request
    @response = Rack::Response.new
  end

  def present(value, options = { scope: ['return'] })
    @present = { value: value, options: options }
  end

  class Abort < StandardError
  end
end
