require_relative '../test_helper'

describe Application, '.resource' do
  include Rack::Test::Methods

  before { @holder = {} }

  def app
    holder = @holder

    app = Class.new(Application)

    app.route('/users', :get)
      .resource { 'User resource' }
      .do_any { holder[:resource] = resource }

    app
  end

  it 'sets and gets resource' do
    get '/users'

    expect(last_response).to be_ok
    expect(@holder[:resource]).to eq 'User resource'
  end
end
