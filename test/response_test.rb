require "minitest/autorun"
require "rack/test"
require "pry"

require_relative '../lib/app'

class DoAnyTest < Minitest::Test
  include Rack::Test::Methods

  def app
    app = App.new

    app.route('/users', :get)
      .do_any { self.body = 'Hello, do anyway!' }

    app
  end

  def test_set_response_entity
    get '/users'

    assert last_response.ok?
    assert_equal last_response.body, 'Hello, do anyway!'
  end
end
