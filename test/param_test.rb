require "minitest/autorun"
require "rack/test"
require "pry"

require 'json'
require_relative '../lib/app'

class ParamTest < Minitest::Test
  include Rack::Test::Methods

  def app
    @holder = []
    holder = @holder

    app = App.new

    app.route('/users', :post)
      .param(:name)
      .param(:age)
      .do_any { 
        holder[0] = params 
      }

    app
  end

  def test_pass_params
    post('/users', JSON.generate(name: 'Jim', age: 18, foo: 'bar'), { 'CONTENT_TYPE' => 'application/json' })

    assert last_response.ok?

    assert_equal @holder[0], { name: 'Jim', age: 18 }
  end
end
