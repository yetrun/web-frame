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
end
