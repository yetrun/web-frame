require 'pry'
require "rack/test"
require_relative '../lib/application'

describe Application, '.route' do
  include Rack::Test::Methods

  def app
    @holder = []
    holder = @holder

    app = Class.new(Application)

    app.route('/users', :get)
      .do_any { holder[0] = 'users'; holder[1] = :get }

    app.route('/users/:id', :get)
      .do_any { holder[0] = request.params }

    app.route('/users', :post)
      .do_any { holder[0] = 'users'; holder[1] = :post }

    app.route('/posts', :get)
      .do_any { holder[0] = 'posts'; holder[1] = :get }

    app
  end

  it '调用 GET /users 接口' do
    get '/users'

    expect(last_response.ok?).to be true

    expect(@holder[0]).to eq 'users'
    expect(@holder[1]).to eq :get
  end

  it '调用 POST /users 接口' do
    post '/users'

    expect(last_response.ok?).to be true

    expect(@holder[0]).to eq 'users'
    expect(@holder[1]).to eq :post
  end

  it '调用 GET /posts 接口' do
    get '/posts'

    expect(last_response.ok?).to be true

    expect(@holder[0]).to eq 'posts'
    expect(@holder[1]).to eq :get
  end

  it '调用 GET /users/:id 接口' do
    get '/users/1'

    expect(last_response.ok?).to be true

    expect(@holder[0]).to eq('id' => '1')
  end

  it '调用不匹配的接口' do
    expect { post '/posts' }.to raise_error(Errors::NoMatchingRouteError)
    expect { get '/unknown' }.to raise_error(Errors::NoMatchingRouteError)
  end
end
