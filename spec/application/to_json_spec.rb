require_relative '../test_helper'

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

  it 'invokes `resource.to_json`' do
    get '/resource'

    expect(last_response.status).to eq 200
    expect(last_response.body).to eq 'resource'
  end
end
