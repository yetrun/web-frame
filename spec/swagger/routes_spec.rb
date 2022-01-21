require 'spec_helper'
require_relative '../../lib/swagger_doc'
require 'json'
require 'grape-entity'

describe 'SwaggerDocUtil.generate' do
  subject { SwaggerDocUtil.generate(app) }

  shared_examples 'generating routes documentation' do
    it 'generates documentation of routes' do
      expect(subject[:paths]).to match(
        "/users" => {
          get: an_instance_of(Hash),
          post: an_instance_of(Hash),
        },
        "/posts" => {
          get: an_instance_of(Hash),
          post: an_instance_of(Hash)
        }
      ) 
    end
  end

  describe 'generating routes documentation' do
    context 'singular module' do
      let(:app) do
        app = Class.new(Application)

        app.route('/users', :get)
        app.route('/users', :post)
        app.route('/posts', :get)
        app.route('/posts', :post)

        app
      end

      include_examples 'generating routes documentation'
    end

    context 'including multiple modules' do
      let (:users_app) do
        Class.new(Application) do
          route('/users', :get)
          route('/users', :post)
        end
      end
      
      let(:posts_app) do
        Class.new(Application) do
          route('/posts', :get)
          route('/posts', :post)
        end
      end

      let(:app) do
        app = Class.new(Application)

        app.apply users_app
        app.apply posts_app

        app
      end

      include_examples 'generating routes documentation'
    end
  end
end
