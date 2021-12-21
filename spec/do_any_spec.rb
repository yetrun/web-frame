require "rack/test"
require_relative '../lib/framework'

describe 'Framework#do_any' do
  include Rack::Test::Methods

  def app
    app = Framework.new

    app.route('/users', :get)
      .do_any { response.body = 'Hello, do anyway!' }

    app
  end

  it '设置返回实体' do
    get '/users'

    expect(last_response.ok?).to be true
    expect(last_response.body).to eq 'Hello, do anyway!'
  end
end
