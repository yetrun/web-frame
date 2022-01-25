require 'spec_helper'

describe Application do
  describe 'default status' do
    it 'sets status code' do
      response = Rack::Response.new
      expect(response.status).to eq 200
    end
  end

  describe '.set_status' do
    def app
      app = Class.new(Application)

      app.route('/status', :get)
        .set_status { 201 }

      app
    end

    it 'sets status code' do
      get '/status'

      expect(last_response.status).to eq 201
    end
  end

  describe '.if_status' do
    def app
      app = Class.new(Application)

      app.route('/status', :get)
        .do_any {
          response.status = 201
        }
        .if_status(200) {
          output(:status) { 'ok' }
        }
        .if_status(201) {
          output(:status) { 'created' }
        }
        .if_status(202) {
          output(:status) { 'accepted' }
        }

      app
    end

    it 'filters status' do
      get '/status'

      expect(last_response.status).to eq 201
      expect(JSON.parse(last_response.body)).to eq('status' => 'created')
    end
  end
end
