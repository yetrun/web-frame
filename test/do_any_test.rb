require "minitest/autorun"
require "rack/test"
require "pry"

require_relative '../lib/app'

class DoAnyTest < Minitest::Test
  include Rack::Test::Methods

  def app
    app = App.new

    app.route('/users', :get)
      .do_any { [200, { 'Content-Type' => 'text/plain' }, [ 'Hello, do any!' ]] }

    app
  end

  def test_do_any_return_response_entity
    get '/users'

    assert last_response.ok?
    assert_equal last_response.body, 'Hello, do any!'
  end
end
