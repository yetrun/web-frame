# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/swagger_doc'

describe 'Dain::SwaggerDocUtil.generate' do
  describe '生成 parameters 文档' do
    subject { Dain::SwaggerDocUtil.generate(app) }

    let(:app) do
      app = Class.new(Dain::Application)

      app.route('/users/:id', :get)
        .parameters {
          param :id, type: 'string', in: 'path', required: true, description: 'the id'
          param :name, type: 'string', in: 'query', description: 'the name'
          param :age, type: 'integer', in: 'query', description: 'the age'
        }

      app
    end

    it 'generates path and query params' do
      expect(subject[:paths]['/users/{id}'][:get][:parameters]).to eq [
        {
          name: :id,
          in: 'path',
          type: 'string',
          required: true,
          description: 'the id'
        },
        {
          name: :name,
          in: 'query',
          type: 'string',
          required: false,
          description: 'the name'
        },
        {
          name: :age,
          in: 'query',
          type: 'integer',
          required: false,
          description: 'the age'
        }
      ]
    end
  end
end
