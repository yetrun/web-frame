require 'spec_helper'
require "rack/test"

describe Application, '.do_any' do
  include Rack::Test::Methods

  before { @holder = {} }

  def app
    holder = @holder

    app = Class.new(Application)

    app.route('/users', :get)
      .do_any { holder[:value] = 'Hello, do something!'}

    app
  end

  it 'invokes the block passing to do_any method' do
    get '/users'

    expect(last_response.ok?).to be true
    expect(@holder[:value]).to eq 'Hello, do something!'
  end
end
