require "rack/test"
require_relative '../lib/framework'

describe 'Framework#route' do
  include Rack::Test::Methods

  def app
    @holder = []
    holder = @holder

    app = Framework.new

    app.route('/users', :get)
      .do_any { holder[0] = 'users'; holder[1] = :get }

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
end
