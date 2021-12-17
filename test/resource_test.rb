require "minitest/autorun"
require "rack/test"
require "pry"

require_relative '../lib/app'

class ResourceTest < Minitest::Test
  include Rack::Test::Methods

  def app
    @holder = []
    holder = @holder

    app = App.new

    app.route('/users', :get)
      .resource { 'User resource' }
      .do_any { holder[0] = resource }

    app
  end

  def test_do_any_return_response_entity
    get '/users'

    assert last_response.ok?
    assert_equal last_response.body, 'Hello, app!'

    assert_equal @holder[0], 'User resource'
  end
end
