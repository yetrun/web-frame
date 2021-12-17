require "rack/test"
require 'json'
require_relative '../lib/framework'

describe 'Framework#authorize' do
  include Rack::Test::Methods

  def app
    @holder = []
    holder = @holder

    app = Framework.new

    app.route('/permit', :get)
      .authorize { true }
      .do_any { holder[0] = 'permitted'}

    app.route('/not_permit', :get)
      .authorize { false }
      .do_any { holder[0] = 'not_permitted'}

    app
  end

  it '调用允许接口' do
    get '/permit'

    expect(last_response.status).to eq 200
    expect(@holder[0]).to eq 'permitted'
  end

  it '调用不允许接口' do
    get '/not_permit'

    expect(last_response.body).to eq 'Not permitted!'
    expect(@holder.empty?).to be true
  end
end
