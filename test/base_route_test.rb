require "minitest/autorun"
require "rack/test"
require "pry"

require_relative '../lib/app'

class BaseRouteTest < Minitest::Test
  include Rack::Test::Methods

  def app
    @holder = []
    holder = @holder

    app = App.new

    app.route('/users', :get)
      .do_any { holder[0] = 'users'; holder[1] = :get }

    app.route('/users', :post)
      .do_any { holder[0] = 'users'; holder[1] = :post }

    app.route('/posts', :get)
      .do_any { holder[0] = 'posts'; holder[1] = :get }

    app
  end

  def test_get_users
    get '/users'

    assert last_response.ok?
    assert_equal last_response.body, 'Hello, app!'

    assert_equal @holder[0], 'users'
    assert_equal @holder[1], :get
  end

  def test_post_users
    post '/users'

    assert last_response.ok?
    assert_equal last_response.body, 'Hello, app!'

    assert_equal @holder[0], 'users'
    assert_equal @holder[1], :post
  end

  def test_get_posts
    get '/posts'

    assert last_response.ok?
    assert_equal last_response.body, 'Hello, app!'

    assert_equal @holder[0], 'posts'
    assert_equal @holder[1], :get
  end
end
