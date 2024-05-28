# frozen_string_literal: true

require 'spec_helper'
require 'json'
require 'grape-entity'

describe 'Meta::SwaggerDocUtil.generate' do
  describe 'generating parameters documentation' do
    describe 'path params' do
      subject { Meta::SwaggerDocUtil.generate(app) }

      let(:app) do
        app = Class.new(Meta::Application)

        app.route('/users/:id', :get)
          .params {
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
            required: true,
            description: 'the id',
            schema: { type: 'string' }
          },
          {
            name: :name,
            in: 'query',
            required: false,
            description: 'the name',
            schema: { type: 'string' }
          },
          {
            name: :age,
            in: 'query',
            required: false,
            description: 'the age',
            schema: { type: 'integer' }
          }
        ]
      end
    end

    describe 'body params' do
      subject do 
        Meta::SwaggerDocUtil.generate(app)[:paths]['/users'][:post][:requestBody][:content]['application/json'][:schema]
      end

      context 'with simple parameters' do # 同时包含了 type 和 description 的测试
        let(:app) do
          app = Class.new(Meta::Application)

          app.route('/users', :post)
            .params {
              param :str, type: 'string', description: '字符串参数' 
              param :int, type: 'integer', description: '整型参数'
              param :hash, type: 'object', description: '对象参数'
              param :array, type: 'array', description: '数组参数'
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
                description: '数组参数',
                items: {}
              },
              any: {}
            }
          )
        end
      end

      context 'with nesting parameters' do
        context 'nesting hash' do # 同时包含 description 的测试
          let(:app) do
            app = Class.new(Meta::Application)

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
            app = Class.new(Meta::Application)

            app.route('/users', :post)
              .params {
                param :users, type: 'array', description: '用户数组' do
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

      describe '不生成 requestBody' do
        subject do 
          Meta::SwaggerDocUtil.generate(app)[:paths]['/users'][:post]
        end

        let(:app) do
          app = Class.new(Meta::Application)

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

    context 'with setting param to `false`' do
      subject do
        Meta::SwaggerDocUtil.generate(app)[:paths]['/request'][:post][:requestBody][:content]['application/json'][:schema]
      end

      let(:app) do
        app = Class.new(Meta::Application)

        app.route('/request', :post)
           .params {
             property :foo, type: 'string', param: false
             property :bar, type: 'string'
           }

        app
      end

      it '只渲染 `bar` 参数' do
        expect(subject).to eq(
                             type: 'object',
                             properties: {
                               bar: { type: 'string' }
                             }
                           )
      end

      context '嵌套' do
        subject do
          Meta::SwaggerDocUtil.generate(app)[:paths]['/request'][:post][:requestBody][:content]['application/json'][:schema]
        end

        let(:app) do
          Class.new(Meta::Application) do
            post '/request' do
              params do
                param :nested do
                  property :foo, type: 'string', param: false
                  property :bar, type: 'string'
                end
              end
            end
          end
        end

        it '不渲染 param 为 false 的参数' do
          expect(subject[:properties][:nested][:properties].keys).to eq([:bar])
        end
      end
    end

    context '使用 `using: Entity`' do
      subject(:doc) do
        Meta::SwaggerDocUtil.generate(app)
      end

      subject(:schema) do
        Meta::SwaggerDocUtil.generate(app)[:paths]['/user'][:post][:requestBody][:content]['application/json'][:schema]
      end

      subject(:components) do
        doc[:components]
      end

      def app
        user_entity = Class.new(Meta::Entity) do
          schema_name 'User'

          property :name, type: 'string'
          property :age, type: 'integer'
        end
        Class.new(Meta::Application) do
          post '/user' do
            params do
              param :user, using: user_entity
            end
          end
        end
      end

      it do
        expect(schema).to eq(
          type: 'object',
          properties: {
            user: {
              '$ref': '#/components/schemas/UserParams'
            }
          }
        )
        expect(components[:schemas]['UserParams']).to eq(
          type: 'object',
          properties: {
            name: { type: 'string' },
            age: { type: 'integer' }
          }
        )
      end
    end

    describe 'route scope' do
      subject(:doc) do
        Meta::SwaggerDocUtil.generate(app)
      end

      subject(:schema) do
        Meta::SwaggerDocUtil.generate(app)[:paths]['/request'][:post][:requestBody][:content]['application/json'][:schema]
      end

      subject(:components) do
        doc[:components]
      end

      def app
        Class.new(Meta::Application) do
          post '/request' do
            scope '$foo'
            params do
              param :foo, scope: '$foo'
              param :bar, scope: '$post'
            end
          end
        end
      end

      it do
        expect(schema).to eq(
          type: 'object',
          properties: {
            foo: {},
            bar: {}
          }
        )
      end
    end
  end
end
