require "minitest/autorun"
require "rack/test"
require "pry"

require_relative 'framework'

class FrameworkTest < Minitest::Test
  include Rack::Test::Methods

  def app
    @holder = []
    holder = @holder

    app = Framework.new
    app.path('/users')
      .do_any { holder[0] = 'users' }
    app.path('/posts')
      .do_any { holder[0] = 'posts' }

    app
  end

  def test_invoke_users_api
    get '/users'

    assert last_response.ok?
    assert_equal last_response.body, 'Hello, Framework!'

    assert_equal @holder[0], 'users'
  end

  def test_invoke_posts_api
    get '/posts'

    assert last_response.ok?
    assert_equal last_response.body, 'Hello, Framework!'

    assert_equal @holder[0], 'posts'
  end
end
