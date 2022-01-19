require 'spec_helper'
require_relative '../../lib/swagger_doc'
require 'json'
require 'grape-entity'

describe 'SwaggerDocUtil.generate' do
  subject { SwaggerDocUtil.generate(app) }

  let(:app) do
    app = Class.new(Application)
    app
  end

  it 'generates swagger documentation' do
    expect(subject).to include(openapi: '3.0.0')
  end

  describe 'generating routes documentation' do
    let(:app) do
      app = Class.new(Application)

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

  describe 'generating parameters documentation' do
    let(:app) do
      app = Class.new(Application)

      app.route('/users', :post)
        .params {
          param :name
          param :age
        } 

      app
    end

    it 'generates documentation of params' do
      expect(subject[:paths]['/users'][:post][:requestBody][:content]['application/json'][:schema]).to eq(
        type: 'object',
        properties: {
          name: {},
          age: {}
        }
      ) 
    end
  end

  describe 'generating responses documentation' do
    let(:app) do
      app = Class.new(Application)

      entity_class = Class.new(Grape::Entity) do
        expose :name
        expose :age
      end

      app.route('/user', :get)
        .exposures {
          expose(:user, entity_class) {}
        }

      app
    end

    it 'generates documentation of responses' do
      expect(subject[:paths]['/user'][:get][:responses]['200'][:content]['application/json'][:schema]).to eq(
        type: 'object',
        properties: {
          user: {
            type: 'object',
            properties: {
              name: {},
              age: {}
            }
          }
        }
      )
    end
  end
end
