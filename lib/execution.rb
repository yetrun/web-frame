require 'rack'

class Execution
  attr_accessor :request
  attr_accessor :response

  def initialize(request)
    @request = request
  end

  def request
    @request
  end

  def response
    @response = @response || Rack::Response.new
  end

  class Abort < StandardError
  end
end
