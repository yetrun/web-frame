require_relative '../test_helper'

describe Application, 'exposing' do
  include Rack::Test::Methods

  let(:app) do
    app = Class.new(Application)

    app
  end

  shared_examples 'expose' do |options = {}|
    key = options[:key]

    subject {
      get '/resource'

      json = JSON.parse(last_response.body)
      key ? json[key] : json
    }

    context 'when resource is a primitive value' do
      let(:resource) { 'value' }

      it { is_expected.to eq('value') }
    end

    context 'when resource is a hash' do
      let(:resource) { { foo: 'bar' }}

      it { is_expected.to eq('foo' => 'bar') }
    end

    context 'when resource responds to `as_json`' do
      let(:resource) {
        resource = Object.new
        def resource.as_json; 'the resource' end

        resource
      }

      it { is_expected.to eq('the resource') }
    end
  end

  describe '.expose' do
    context 'when not specifying a key' do
      before do
        the_resource = resource

        app.route('/resource', :get)
          .expose { the_resource }
      end

      it_behaves_like 'expose'
    end

    context 'when specifying a key' do
      before do
        the_resource = resource

        app.route('/resource', :get)
          .expose(:root) { the_resource }
      end

      it_behaves_like 'expose', key: 'root'
    end
  end

  describe '.expose_resource' do
    context 'when not specifying a key' do
      before do
        the_resource = resource

        app.route('/resource', :get)
          .resource { the_resource }
          .expose_resource
      end

      it_behaves_like 'expose'
    end

    context 'when specifying a key' do
      before do
        the_resource = resource

        app.route('/resource', :get)
          .resource { the_resource }
          .expose_resource(:root)
      end

      it_behaves_like 'expose', key: 'root'
    end
  end
end
