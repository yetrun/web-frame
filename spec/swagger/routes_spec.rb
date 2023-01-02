require 'spec_helper'
require 'json'
require 'grape-entity'

describe 'Meta::SwaggerDocUtil.generate' do
  subject { Meta::SwaggerDocUtil.generate(app) }

  describe '生成 paths 部分' do
    context 'singular module' do
      let(:app) do
        app = Class.new(Meta::Application)

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
        users_app = Class.new(Meta::Application) do
          route('/users', :get)
          route('/users', :post)
        end
        posts_app = Class.new(Meta::Application) do
          route('/posts', :get)
          route('/posts', :post)
        end

        app = Class.new(Meta::Application)

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
        app = Class.new(Meta::Application)

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

  describe '生成 paths.description 部分' do
    let(:app) do
      app = Class.new(Meta::Application)

      app.route('/users', :get)
        .title('查看用户列表')
        .description('此接口返回用户的列表')

      app
    end

    it 'generates title and description' do
      expect(subject[:paths]['/users'][:get]).to match(a_hash_including(
        summary: '查看用户列表',
        description: '此接口返回用户的列表'
      ))
    end
  end
end
