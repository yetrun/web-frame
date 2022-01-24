# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/swagger_doc'
require 'json'
require 'grape-entity'

describe 'SwaggerDocUtil.generate' do

  describe 'generating parameters documentation' do
    describe 'path params' do
      subject { SwaggerDocUtil.generate(app) }

      let(:app) do
        app = Class.new(Application)

        app.route('/users/:id', :get)
          .params {
            param :id, type: String, in: 'path', required: true, description: 'the id'
            param :name, type: String, in: 'query', description: 'the name'
            param :age, type: Integer, in: 'query', description: 'the age'
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

    describe 'body params' do
      subject do 
        SwaggerDocUtil.generate(app)[:paths]['/users'][:post][:requestBody][:content]['application/json'][:schema]
      end

      context 'with simple parameters' do # 同时包含了 type 和 description 的测试
        let(:app) do
          app = Class.new(Application)

          app.route('/users', :post)
            .params {
              param :str, type: String, description: '字符串参数' # TODO: 关键字参数的拼写检查
              param :int, type: Integer, description: '整型参数'
              param :hash, type: Hash, description: '对象参数'
              param :array, type: Array, description: '数组参数'
              param :any
            }

          app
        end

        it 'generates schema in `requestBody` part' do
          expect(subject).to eq(
            type: 'object',
            properties: {
              str: {
                type: 'string',
                description: '字符串参数'
              },
              int: {
                type: 'integer',
                description: '整型参数'
              },
              hash: {
                type: 'object',
                description: '对象参数'
              },
              array: {
                type: 'array',
                description: '数组参数'
              },
              any: {}
            }
          )
        end
      end

      context 'with nesting parameters' do
        context 'nesting hash' do # 同时包含 description 的测试
          let(:app) do
            app = Class.new(Application)

            app.route('/users', :post)
              .params {
                param :user, description: '用户' do
                  param :name
                  param :age
                end
              }

            app
          end

          it 'generates schema in `requestBody` part' do
            expect(subject).to eq(
              type: 'object',
              properties: {
                user: {
                  type: 'object',
                  description: '用户',
                  properties: {
                    name: {},
                    age: {}
                  }
                }
              }
            )
          end
        end

        context 'nesting array' do # 同时包含 description 的测试
          let(:app) do
            app = Class.new(Application)

            app.route('/users', :post)
              .params {
                param :users, type: Array, description: '用户数组' do
                  param :name
                  param :age
                end
              }

            app
          end

          it 'generates schema in `requestBody` part' do
            expect(subject).to eq(
              type: 'object',
              properties: {
                users: {
                  type: 'array',
                  description: '用户数组',
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

      describe 'no body params' do
        subject do 
          SwaggerDocUtil.generate(app)[:paths]['/users'][:post]
        end

        let(:app) do
          app = Class.new(Application)

          app.route('/users', :post)
            .params {
              param :name, in: 'query'
              param :age, in: 'query'
            }

          app
        end

        it 'generates no `requestBody` part' do
          expect(subject).not_to have_key(:requestBody)
        end
      end
    end
  end
end
