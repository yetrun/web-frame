require "rack/test"
require_relative '../lib/framework'

describe 'Framework#resource' do
  include Rack::Test::Methods

  def app
    @holder = []
    holder = @holder

    app = Class.new(Framework)

    app.route('/users', :get)
      .resource { 'User resource' }
      .do_any { holder[0] = resource }

    app
  end

  it '测试 resource 逻辑' do
    get '/users'

    expect(last_response.ok?).to be true

    expect(@holder[0]).to eq 'User resource'
  end
end
