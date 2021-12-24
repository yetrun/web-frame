require "rack/test"
require 'json'
require_relative '../lib/application'

describe Application, '.to_json' do
  include Rack::Test::Methods

  def app
    resource = double('resource')
    allow(resource).to receive(:to_json).and_return('resource')

    @resource = resource

    app = Class.new(Application)

    app.route('/resource', :get)
      .resource { resource }
      .to_json

    app
  end

  it 'to_json 调用 resource.to_json' do
    get '/resource'

    expect(last_response.status).to eq 200
    expect(last_response.body).to eq 'resource'
  end
end
