require 'spec_helper'
require_relative '../../lib/swagger_doc'
require 'json'
require 'grape-entity'

describe 'SwaggerDocUtil.generate' do

  subject { SwaggerDocUtil.generate(app) }

  describe 'generating parameters documentation' do
    context 'with simple parameters' do
      let(:app) do
        app = Class.new(Application)

        app.route('/users', :post)
          .params {
            param :name
            param :age
          } 

        app
      end

      it 'generates documentation of parameters' do
        expect(subject[:paths]['/users'][:post][:requestBody][:content]['application/json'][:schema]).to eq(
          type: 'object',
          properties: {
            name: {},
            age: {}
          }
        ) 
      end
    end

    context 'with nesting parameters' do
      context 'nesting hash' do
        let(:app) do
          app = Class.new(Application)

          app.route('/users', :post)
            .params {
              param :user do
                param :name
                param :age
              end
            } 

          app
        end

        it 'generates documentation of parameters' do
          expect(subject[:paths]['/users'][:post][:requestBody][:content]['application/json'][:schema]).to eq(
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

      context 'nesting array' do
        let(:app) do
          app = Class.new(Application)

          app.route('/users', :post)
            .params {
              param :users, type: Array do
                param :name
                param :age
              end
            } 

          app
        end

        it 'generates documentation of parameters' do
          expect(subject[:paths]['/users'][:post][:requestBody][:content]['application/json'][:schema]).to eq(
            type: 'object',
            properties: {
              users: {
                type: 'array',
                items: {
                  type: 'object',
                  properties: {
                    name: {},
                    age: {}
                  }
                }
              }
            }
          ) 
        end
      end
    end
  end
end
