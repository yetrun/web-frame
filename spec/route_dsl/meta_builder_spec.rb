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

    context '父级定义参数' do
      def app
        Class.new(Dain::Application) do
          namespace '/foo' do
            parameters do
              param :foo, type: 'string', in: 'query'
            end

            before do
              @foo_in_namespace = parameters[:foo]
            end

            get '/bar' do
              parameters do
                param :bar, type: 'string', in: 'query'
              end
              action do
                response.body = [{
                  foo_in_namespace: @foo_in_namespace,
                  foo_in_route: parameters[:foo],
                  bar_in_route: parameters[:bar]
                }.to_json]
              end
            end
          end
        end
      end

      it '传递 parameters 成功' do
        get '/foo/bar?foo=foo&bar=bar', { 'CONTENT_TYPE' => 'application/json' }
        expect(JSON.parse(last_response.body)).to eq({
          'foo_in_namespace' => 'foo',
          'foo_in_route' => 'foo',
          'bar_in_route' => 'bar'
        })
      end
    end

    context '父级定义参数（三级嵌套）' do
      def app
        Class.new(Dain::Application) do
          namespace '/foo' do
            parameters do
              param :foo, type: 'string', in: 'query'
            end

            before do
              @foo1 = parameters[:foo]
            end

            namespace '/bar' do
              parameters do
                param :bar, type: 'string', in: 'query'
              end

              before do
                @foo2 = parameters[:foo]
                @bar2 = parameters[:bar]
              end

              get '/baz' do
                parameters do
                  param :baz, type: 'string', in: 'query'
                end
                action do
                  response.body = [{
                    foo1: @foo1,
                    foo2: @foo2,
                    foo3: parameters[:foo],
                    bar2: @bar2,
                    bar3: parameters[:bar],
                    baz3: parameters[:baz]
                  }.to_json]
                end
              end
            end
          end
        end
      end

      it '传递 parameters 成功' do
        get '/foo/bar/baz?foo=foo&bar=bar&baz=baz', { 'CONTENT_TYPE' => 'application/json' }
        expect(JSON.parse(last_response.body)).to eq({
          'foo1' => 'foo',
          'foo2' => 'foo',
          'foo3' => 'foo',
          'bar2' => 'bar',
          'bar3' => 'bar',
          'baz3' => 'baz',
        })
      end
    end
  end

  describe 'request and response body' do
    context '使用 request_body' do
      def app
        Class.new(Dain::Application) do
          route '/request', :post do
            request_body do
              property :foo, type: 'string'
            end
            action do
              response.body = [JSON.generate(request_body)]
            end
          end
        end
      end

      it '成功传递和解析参数' do
        post '/request', JSON.generate(foo: 'foo', bar: 'bar'), { 'CONTENT_TYPE' => 'application/json'}
        expect(JSON.parse(last_response.body)).to eq('foo' => 'foo')
      end
    end

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
