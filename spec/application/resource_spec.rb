require 'spec_helper'

describe Meta::Application, '.resource' do
  include Rack::Test::Methods

  context '返回一个 nil 值' do
    def app
      app = Class.new(Meta::Application)

      app.route('/users', :get)
        .resource { nil }

      app
    end

    it 'sets and gets resource' do
      expect { get '/users' }.to raise_error(Meta::Errors::ResourceNotFound)
    end
  end

  context '返回一个非 nil 值' do
    def app
      holder = @holder = []

      app = Class.new(Meta::Application)

      app.route('/users', :get)
        .resource { "Self is a execution: #{self.is_a?(Meta::Execution)}" }
        .do_any { holder[0] = resource }

      app
    end

    it 'sets and gets resource' do
      get '/users'

      expect(last_response).to be_ok
      expect(@holder[0]).to eq 'Self is a execution: true'
    end
  end
end
