require_relative '../test_helper'

describe Application, '.status' do
  def app
    app = Class.new(Application)

    app.route('/status', :get)
      .status(201)

    app
  end

  it 'sets status code' do
    get '/status'

    expect(last_response.status).to eq 201
  end
end
