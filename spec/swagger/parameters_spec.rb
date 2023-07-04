# frozen_string_literal: true

require 'spec_helper'

describe 'Meta::SwaggerDocUtil.generate' do
  describe '生成 parameters 文档' do
    subject { app.to_swagger_doc }

    context '无参数' do
      def app
        Class.new(Meta::Application) do
          get '/request'
        end
      end

      it '不包含 parameters 块' do
        expect(subject[:paths]['/request'][:get].keys).not_to include(:parameters)
      end
    end

    context '路径中包含参数' do
      context '未使用 parameters 宏' do
        context '单层示例' do
          def app
            Class.new(Meta::Application) do
              get '/users/:id'
            end
          end

          it '自动提供参数的文档' do
            expect(subject[:paths]['/users/{id}'][:get][:parameters]).to eq [
              {
                name: :id,
                in: 'path',
                required: true,
                description: '',
                schema: {}
              }
            ]
          end
        end

        context '多层示例' do
          def app
            Class.new(Meta::Application) do
              namespace '/:foo' do
                get '/:bar'
              end
            end
          end

          it '自动提供参数的文档' do
            expect(subject[:paths]['/{foo}/{bar}'][:get][:parameters]).to eq [
              {
                name: :foo,
                in: 'path',
                required: true,
                description: '',
                schema: {}
              },
              {
                name: :bar,
                in: 'path',
                required: true,
                description: '',
                schema: {}
              }
            ]
          end
        end

        context 'apply 示例' do
          def app
            mod = Class.new(Meta::Application) do
              get '/:bar'
            end
            Class.new(Meta::Application) do
              namespace '/:foo' do
                apply mod
              end
            end
          end

          it '自动提供参数的文档' do
            expect(subject[:paths]['/{foo}/{bar}'][:get][:parameters]).to eq [
              {
                name: :foo,
                in: 'path',
                required: true,
                description: '',
                schema: {}
              },
              {
                name: :bar,
                in: 'path',
                required: true,
                description: '',
                schema: {}
              }
            ]
          end
        end
      end

      context '使用 parameters 宏' do
        context '未覆盖 in 和 required 选项' do
          def app
            Class.new(Meta::Application) do
              get '/users/:id' do
                parameters do
                  param :id, type: 'string', description: 'the id'
                end
              end
            end
          end

          it '自动提供参数的文档' do
            expect(subject[:paths]['/users/{id}'][:get][:parameters][0]).to eq({
              name: :id,
              in: 'path',
              required: true,
              description: 'the id',
              schema: { type: 'string' }
            })
          end
        end

        context '覆盖 in 和 required 选项' do
          def app
            Class.new(Meta::Application) do
              get '/users/:id' do
                parameters do
                  param :id, type: 'string', in: 'path', required: true, description: 'the id'
                  param :name, type: 'string', in: 'query', description: 'the name'
                  param :age, type: 'integer', in: 'query', description: 'the age'
                end
              end
            end
          end

          it '成功生成 path 和 query 参数的文档' do
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
      end

      context '使用 params 宏' do
        def app
          Class.new(Meta::Application) do
            get '/request/:foo/:bar' do
              params do
                param :foo, type: 'string', description: 'the foo'
              end
            end
          end
        end

        it '自动提供参数的文档' do
          expect(subject[:paths]['/request/{foo}/{bar}'][:get][:parameters]).to match([
            {
              name: :foo,
              in: 'path',
              required: true,
              description: 'the foo',
              schema: { type: 'string' }
            },
            a_hash_including(
              name: :bar,
              in: 'path',
              required: true
            )
          ])
        end
      end
    end

    describe '定义 query 参数' do
      context '用 parameters 宏定义' do
        def app
          Class.new(Meta::Application) do
            get '/request' do
              parameters do
                param :name, type: 'string', in: 'query', description: 'the name'
                param :age, type: 'integer', in: 'query', description: 'the age'
              end
            end
          end
        end

        it '成功生成 path 和 query 参数的文档' do
          expect(subject[:paths]['/request'][:get][:parameters]).to eq [
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

      context '用 params 宏定义' do
        def app
          Class.new(Meta::Application) do
            get '/request' do
              params do
                param :name, type: 'string', description: 'the name'
                param :age, type: 'integer', description: 'the age'
              end
            end
          end
        end

        it '默认生成 query 参数' do
          expect(subject[:paths]['/request'][:get][:parameters]).to eq [
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
    end
  end
end
