require "minitest/autorun"
require "rack/test"
require "pry"

require 'json'
require_relative '../lib/app'

class AuthorizeTest < Minitest::Test
  include Rack::Test::Methods

  def app
    @holder = []
    holder = @holder

    app = App.new

    app.route('/permit', :get)
      .authorize { true }
      .do_any { holder[0] = 'permitted'}

    app.route('/not_permit', :get)
      .authorize { false }
      .do_any { holder[0] = 'not_permitted'}

    app
  end

  def test_permit
    get '/permit'

    assert last_response.status, 200
    assert_equal @holder[0], 'permitted'
  end

  def test_not_permit
    get '/not_permit'

    assert_equal last_response.body, 'Not permitted!'
    assert @holder.empty?
  end
end
