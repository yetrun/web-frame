require 'spec_helper'

describe Dain::Application, '.resource' do
  include Rack::Test::Methods

  before { @holder = {} }

  def app
    holder = @holder

    app = Class.new(Dain::Application)

    app.route('/users', :get)
      .resource { "Self is a execution: #{self.is_a?(Dain::Execution)}" }
      .do_any { holder[:resource] = resource }

    app
  end

  it 'sets and gets resource' do
    get '/users'

    expect(last_response).to be_ok
    expect(@holder[:resource]).to eq 'Self is a execution: true'
  end
end
