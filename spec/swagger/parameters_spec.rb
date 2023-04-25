# frozen_string_literal: true

require 'spec_helper'

describe 'Meta::SwaggerDocUtil.generate' do
  describe '生成 parameters 文档' do
    subject { app.to_swagger_doc }

    context '定义 path、query 参数' do
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

    context '路径存在 path 参数，但参数宏中未提供 path 定义' do
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

    context 'parameters 定义为空' do
      def app
        Class.new(Meta::Application) do
          get '/request'
        end
      end

      it '不包含 parameters 块' do
        expect(subject[:paths]['/request'][:get].keys).not_to include(:parameters)
      end
    end
  end
end
