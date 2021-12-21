require 'rack'

class Execution
  attr_accessor :request
  attr_accessor :response
  attr_accessor :env
  attr_accessor :params

  def initialize(env)
    @env = env
    @params = {}
  end

  def request
    return @request if @request

    @request = Rack::Request.new(@env)

    request_io = env['rack.input']
    request_body = request_io.read
    return @request if request_body.empty?

    # 将参数集中获取
    request_params = JSON.parse(request_body)
    request_params.each do |key, val|
      key = key.to_s
      @request.update_param(key, val) unless @request.params.key?(key)
    end

    @request
  end

  def response
    @response = @response || Rack::Response.new
  end

  class Abort < StandardError
  end
end
