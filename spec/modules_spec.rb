require "rack/test"
require_relative '../lib/application'

describe Application, '.mount' do
  include Rack::Test::Methods

  def app
    users_app = Class.new(Application)
    users_app.route('/users', :get)
      .do_any { response.body = 'Hello, users!' }

    posts_app = Class.new(Application)
    posts_app.route('/posts', :get)
      .do_any { response.body = 'Hello, posts!' }

    app = Class.new(Application)
    app.apply users_app
    app.apply posts_app

    app
  end

  it '响应 /users' do
    get '/users'

    expect(last_response.ok?).to be true
    expect(last_response.body).to eq 'Hello, users!'
  end

  it '响应 /posts' do
    get '/posts'

    expect(last_response.ok?).to be true
    expect(last_response.body).to eq 'Hello, posts!'
  end
end
