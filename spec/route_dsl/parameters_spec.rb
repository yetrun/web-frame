# frozen_string_literal: true

require 'spec_helper'

# 这里是仅含 in 选项为 path, query, header 的测试，不包含 body
describe '纯粹的 parameters 块的测试' do
  describe '定义数组参数' do
    context '使用 form 参数' do
      shared_examples '测试数组参数' do |macro_name:|
        let(:app) do
          Class.new(Meta::Application) do
            get '/request' do
              send(macro_name) do
                param :colors, type: 'array'
              end
              action do
                response.body = [JSON.generate(params)]
              end
            end
          end
        end

        it '生成数组参数' do
          get '/request?colors[]=red&colors[]=green&colors[]=blue'
          expect(last_response.status).to be 200
          expect(JSON.parse(last_response.body)).to eq('colors' => %w[red green blue])
        end

        it '成功生成 array parameter 文档' do
          doc = app.to_swagger_doc
          expect(doc[:paths]['/request'][:get][:parameters]).to eq [
            {
              name: :colors,
              in: 'query',
              required: false,
              description: '',
              schema: { type: 'array' }
            }
          ]
        end
      end

      context '用 parameters 宏定义' do
        include_examples '测试数组参数', macro_name: :parameters
      end

      context '用 params 宏定义' do
        include_examples '测试数组参数', macro_name: :params
      end
    end

    context '使用 before: 选项' do
      let(:app) do
        Class.new(Meta::Application) do
          get '/request' do
            params do
              param :colors, type: 'array', before: ->(value) { value.split(',') }
            end
            action do
              response.body = [JSON.generate(params)]
            end
          end
        end
      end

      it '生成数组参数' do
        get '/request?colors=red,green,blue'
        expect(last_response.status).to be 200
        expect(JSON.parse(last_response.body)).to eq('colors' => %w[red green blue])
      end

      it '成功生成 array parameter 文档' do
        doc = app.to_swagger_doc
        expect(doc[:paths]['/request'][:get][:parameters]).to eq [
          {
            name: :colors,
            in: 'query',
            required: false,
            description: '',
            schema: { type: 'array' }
          }
        ]
      end
    end
  end

  describe '定义对象参数' do
    shared_examples '测试对象参数' do |macro_name:|
      let(:app) do
        Class.new(Meta::Application) do
          get '/request' do
            send(macro_name) do
              param :color, type: 'object'
            end
            action do
              response.body = [JSON.generate(params)]
            end
          end
        end
      end

      it '生成对象参数' do
        get '/request?color[r]=1&color[g]=2&color[b]=3'
        expect(last_response.status).to be 200
        expect(JSON.parse(last_response.body)).to eq('color' => { 'r' => '1', 'g' => '2', 'b' => '3' })
      end

      it '成功生成 array parameter 文档' do
        doc = app.to_swagger_doc
        expect(doc[:paths]['/request'][:get][:parameters]).to eq [
          {
            name: :color,
            in: 'query',
            required: false,
            description: '',
            schema: { type: 'object' }
          }
        ]
      end
    end

    context '用 parameters 宏定义' do
      include_examples '测试对象参数', macro_name: :parameters
    end

    context '用 params 宏定义' do
      include_examples '测试对象参数', macro_name: :params
    end
  end

  describe '混入其他参数' do
    shared_examples '测试对象参数' do |macro_name:|
      let(:app) do
        token_param = proc do
          param :'X-Token', type: 'string', in: 'header'
        end
        Class.new(Meta::Application) do
          get '/request' do
            send(macro_name) do
              instance_exec &token_param
            end
            action do
              response.body = [JSON.generate(params)]
            end
          end
        end
      end

      it '生成对象参数' do
        get '/request', {}, 'HTTP_X_TOKEN' => 'abc'
        expect(last_response.status).to be 200
        expect(JSON.parse(last_response.body)).to eq('X-Token' => 'abc')
      end

      it '成功生成 array parameter 文档' do
        doc = app.to_swagger_doc
        expect(doc[:paths]['/request'][:get][:parameters]).to eq [
          {
            name: :'X-Token',
            in: 'header',
            required: false,
            description: '',
            schema: { type: 'string' }
          }
        ]
      end
    end

    context '用 parameters 宏定义' do
      include_examples '测试对象参数', macro_name: :parameters
    end

    context '用 params 宏定义' do
      include_examples '测试对象参数', macro_name: :params
    end
  end
end
