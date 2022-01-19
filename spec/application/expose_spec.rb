require_relative '../test_helper'
require 'grape-entity'

describe Application, 'exposing' do
  include Rack::Test::Methods

  let(:key) { nil }

  let(:app) do
    app = Class.new(Application)

    define_route(app.route('/resource', :get))

    app
  end

  subject {
    get '/resource'

    json = JSON.parse(last_response.body)
    key ? json[key] : json
  }

  shared_examples 'exposing object directly' do |options = {}|
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

  shared_examples 'exposing with entity' do
    let(:resource) {
      user = Object.new
      def user.name; 'Jim' end
      def user.age; 18 end

      user
    }

    let(:entity_class) do
      Class.new(Grape::Entity) do
        expose :name
        expose :age
      end
    end

    it { is_expected.to eq('name' => 'Jim', 'age' => 18) }
  end

  describe '.expose' do
    context 'when not specifying a key' do
      context 'without providing an entity' do
        def define_route(route)
          the_resource = resource

          route.expose { the_resource }
        end

        it_behaves_like 'exposing object directly'
      end

      context 'with providing an entity' do
        def define_route(route)
          the_resource = resource

          route.expose(entity_class) { the_resource }
        end

        it_behaves_like 'exposing with entity'
      end
    end

    context 'when specifying a key' do
      let(:key) { 'root' }

      context 'without providing an entity' do
        def define_route(route)
          the_resource = resource

          route.expose(:root) { the_resource }
        end

        it_behaves_like 'exposing object directly'
      end

      context 'with providing an entity' do
        def define_route(route)
          the_resource = resource

          route.expose(:root, entity_class) { the_resource }
        end

        it_behaves_like 'exposing with entity'
      end
    end
  end

  describe '.expose_resource' do
    context 'when not specifying a key' do
      context 'without providing an entity' do
        def define_route(route)
          the_resource = resource

          route.resource { the_resource }
            .expose_resource
        end

        it_behaves_like 'exposing object directly'
      end

      context 'with providing an entity' do
        def define_route(route)
          the_resource = resource

          route.resource { the_resource }
            .expose_resource(entity_class)
        end

        it_behaves_like 'exposing with entity'
      end
    end

    context 'when specifying a key' do
      let(:key) { 'root' }

      context 'without providing an entity' do
        def define_route(route)
          the_resource = resource

          route.resource { the_resource }
            .expose_resource(:root)
        end

        it_behaves_like 'exposing object directly'
      end

      context 'with providing an entity' do
        def define_route(route)
          the_resource = resource

          route.resource { the_resource }
            .expose_resource(:root, entity_class)
        end

        it_behaves_like 'exposing with entity'
      end
    end
  end
end
