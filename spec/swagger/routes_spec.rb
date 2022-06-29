require 'spec_helper'
require_relative '../../lib/swagger_doc'
require 'json'
require 'grape-entity'

describe 'Dain::SwaggerDocUtil.generate' do
  subject { Dain::SwaggerDocUtil.generate(app) }

  describe 'generating route paths part' do
    context 'singular module' do
      let(:app) do
        app = Class.new(Dain::Application)

        app.route('/users', :get)
        app.route('/users', :post)
        app.route('/posts', :get)
        app.route('/posts', :post)

        app
      end

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

    context 'including multiple modules' do
      let(:app) do
        users_app = Class.new(Dain::Application) do
          route('/users', :get)
          route('/users', :post)
        end
        posts_app = Class.new(Dain::Application) do
          route('/posts', :get)
          route('/posts', :post)
        end

        app = Class.new(Dain::Application)

        app.apply users_app
        app.apply posts_app

        app
      end

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

    context 'with path parameters' do
      let(:app) do
        app = Class.new(Dain::Application)

        app.route('/users/:id', :get)
        app.route('/posts/*title', :get)

        app
      end

      it 'generates documentation of routes' do
        expect(subject[:paths]).to match(
          "/users/{id}" => {
            get: an_instance_of(Hash)
          },
          "/posts/{title}" => {
            get: an_instance_of(Hash)
          }
        ) 
      end
    end
  end

  describe 'generating route description part' do
    let(:app) do
      app = Class.new(Dain::Application)

      app.route('/users', :get)
        .title('查看用户列表')
        .description('此接口返回用户的列表')

      app
    end

    it 'generates title and description' do
      expect(subject[:paths]['/users'][:get]).to match(
        summary: '查看用户列表',
        description: '此接口返回用户的列表'
      ) 
    end
  end
end
