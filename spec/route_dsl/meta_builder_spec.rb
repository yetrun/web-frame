# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/route_dsl/application_builder'
require_relative '../../lib/swagger_doc'

describe 'Meta Builder' do
  include Rack::Test::Methods

  describe 'parameters' do
    context '定义简单的 query 参数' do
      def app
        Class.new(Dain::Application) do
          get '/request' do
            parameters do
              param :foo, type: 'string', in: 'query'
            end
            action do
              response.body = [parameters[:foo]]
            end
          end
        end
      end

      it '传递 parameters 成功' do
        get '/request?foo=foo', { 'CONTENT_TYPE' => 'application/json' }
        expect(last_response.body).to eq('foo')
      end
    end

    context '定义 path 参数' do
      def app
        Class.new(Dain::Application) do
          get '/request/:foo' do
            parameters do
              param :foo, type: 'string', in: 'path'
            end
            action do
              response.body = [parameters[:foo]]
            end
          end
        end
      end

      it '传递 parameters 成功' do
        get '/request/foo', { 'CONTENT_TYPE' => 'application/json' }
        expect(last_response.body).to eq('foo')
      end
    end
  end

  describe 'request and response body' do
    context '遇到 `required: true` 时' do
      def app
        entity = Class.new(Dain::Entity) do
          expose :foo
          expose :bar, required: true
        end

        Class.new(Dain::Application) do
          route '/request', :post do
            params do
              param :nested, using: entity
            end
            action do
              params(:discard_missing)
            end
          end
        end
      end

      it '调用 `params(:discard_missing)` 时不报错' do
        expect {
          post '/request', { 'nested' => { 'foo' => 'foo' } }.to_json, { 'CONTENT_TYPE' => 'application/json'}
        }.not_to raise_error
      end
    end

    describe 'render: false' do
      def app
        entity = Class.new(Dain::Entity) do
          expose :foo
          expose :bar, render: false
        end

        Class.new(Dain::Application) do
          route '/request', :post do
            status 200 do
              expose :nested, using: entity
            end
            action do
              render(:'nested', { 'foo' => 'foo', 'bar' => 'bar' })
            end
          end
        end
      end

      it '成功过滤 render 选项为 false 的属性' do
        post '/request'
        expect(JSON.parse(last_response.body)['nested'].keys).to eq(['foo'])
      end
    end

    describe 'value 中使用 Execution 环境' do
      def app
        entity = Class.new(Dain::Entity) do
          expose :foo, value: lambda { resolve_method }
        end

        Class.new(Dain::Application) do
          route '/request', :post do
            status 200 do
              expose :nested, using: entity
            end
            action do
              def self.resolve_method; 'resolved method' end
              render :'nested', {}
            end
          end
        end
      end

      it '成功调用 Execution 环境中的方法' do
        post '/request'
        expect(JSON.parse(last_response.body)).to eq('nested' => { 'foo' => 'resolved method' })
      end
    end
  end
end
