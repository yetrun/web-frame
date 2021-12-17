require "rack/test"
require 'json'
require_relative '../lib/framework'

describe 'Framework#param' do
  include Rack::Test::Methods

  def app
    @holder = []
    holder = @holder

    app = Framework.new

    app.route('/users', :post)
      .param(:name)
      .param(:age)
      .do_any { 
        holder[0] = params 
      }

    app
  end

  it '传递参数' do
    post('/users', JSON.generate(name: 'Jim', age: 18, foo: 'bar'), { 'CONTENT_TYPE' => 'application/json' })

    expect(last_response.ok?).to be true

    expect(@holder[0]).to eq(name: 'Jim', age: 18)
  end
end
