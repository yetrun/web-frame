require_relative '../test_helper'
require_relative '../../lib/swagger_doc'
require 'json'

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
      expect(subject[:routes]).to eq ["GET /users", "POST /users", "GET /posts", "POST /posts"]
    end
  end
end
