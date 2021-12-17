class Execution
  attr_accessor :rack_env
  attr_accessor :request_body
  attr_accessor :body
  attr_accessor :params

  def initialize(env)
    @rack_env = env
    @body = ''
    @params = {}
  end
end
