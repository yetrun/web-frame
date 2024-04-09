# frozen_string_literal: true

require 'spec_helper'

describe 'Meta Builder' do
  include Rack::Test::Methods

  describe 'scope' do
    context '在路由中定义 scope' do
      def app
        Class.new(Meta::Application) do
          post '/request' do
            scope 'foo'
            params do
              param :foo, scope: 'foo'
              param :bar, scope: 'bar'
            end
            action do
              response.body = [JSON.generate(params)]
            end
          end
        end
      end

      it '渲染参数时应用 scope' do
        post '/request', JSON.generate(foo: 'foo', bar: 'bar'), { 'CONTENT_TYPE' => 'application/json' }
        expect(JSON.parse(last_response.body)).to eq({ 'foo' => 'foo' })
      end

      context '请求体 lock_scope' do
        def app
          entity_class = Class.new(Meta::Entity) do
            property :foo, scope: 'foo'
            property :bar, scope: 'bar'
            property :foobar, scope: ['foo', 'bar']
          end

          Class.new(Meta::Application) do
            post '/request' do
              scope 'foo'
              request_body ref: entity_class.lock_scope('bar')
              action do
                response.body = [JSON.generate(params)]
              end
            end
          end
        end

        it '实体锁定的 scope 与路由声明的 scope 合并' do
          post '/request', JSON.generate(foo: 'foo', bar: 'bar', 'foobar' => 'foobar'), { 'CONTENT_TYPE' => 'application/json' }
          expect(JSON.parse(last_response.body)).to eq({ 'foo' => 'foo', 'bar' => 'bar', 'foobar' => 'foobar' })
        end
      end
    end

    context '在 namespace 中定义 scope' do
      def app
        Class.new(Meta::Application) do
          meta do
            scope 'foo'
          end

          post '/request' do
            params do
              param :foo, scope: 'foo'
              param :bar, scope: 'bar'
            end
            action do
              response.body = [JSON.generate(params)]
            end
          end
        end
      end

      it '向下传递到路由的 meta' do
        post '/request', JSON.generate(foo: 'foo', bar: 'bar'), { 'CONTENT_TYPE' => 'application/json' }
        expect(JSON.parse(last_response.body)).to eq({ 'foo' => 'foo' })
      end

      context '路由中继续定义' do
        def app
          Class.new(Meta::Application) do
            meta do
              scope 'foo'
            end

            post '/request' do
              scope 'bar'
              params do
                param :foo, scope: 'foo'
                param :bar, scope: 'bar'
              end
              action do
                response.body = [JSON.generate(params)]
              end
            end
          end
        end

        it '路由中的 scope 与 namespace 的合并' do
          post '/request', JSON.generate(foo: 'foo', bar: 'bar'), { 'CONTENT_TYPE' => 'application/json' }
          expect(JSON.parse(last_response.body)).to eq({ 'foo' => 'foo', 'bar' => 'bar' })
        end
      end

      context '实体引用' do
        let(:entity_class) {
          Class.new(Meta::Entity) do
            property :foo, scope: 'foo'
            property :bar, scope: 'bar'
          end
        }

        def app
          the_entity = entity
          Class.new(Meta::Application) do
            post '/request' do
              scope 'foo'

              params do
                param :nesting, ref: the_entity
              end
              action do
                response.body = [JSON.generate(params)]
              end
            end
          end
        end

        context '只引用 entity_class' do
          let(:entity) { entity_class }

          it '路由中的 scope 与 namespace 的合并' do
            post '/request', JSON.generate(nesting: { foo: 'foo', bar: 'bar' }), { 'CONTENT_TYPE' => 'application/json' }
            expect(JSON.parse(last_response.body)['nesting']).to eq({ 'foo' => 'foo' })
          end
        end

        context '引用的 entity_class 调用 lock_scope' do
          let(:entity) { entity_class.lock_scope('bar') }

          it '路由中的 scope 与 namespace 的合并' do
            post '/request', JSON.generate(nesting: { foo: 'foo', bar: 'bar' }), { 'CONTENT_TYPE' => 'application/json' }
            expect(JSON.parse(last_response.body)['nesting']).to eq({ 'foo' => 'foo', 'bar' => 'bar' })
          end
        end
      end
    end

    context 'HTTP 方法自动定义 scope' do
      def app
        Class.new(Meta::Application) do
          post '/request' do
            params do
              param :foo, scope: '$post'
              param :bar, scope: '$put'
            end
            action do
              response.body = [JSON.generate(params)]
            end
          end
        end
      end

      it '渲染参数时应用 scope' do
        post '/request', JSON.generate(foo: 'foo', bar: 'bar'), { 'CONTENT_TYPE' => 'application/json' }
        expect(JSON.parse(last_response.body)).to eq({ 'foo' => 'foo' })
      end
    end
  end

  describe 'parameters' do
    context '定义 query 参数' do
      def app
        Class.new(Meta::Application) do
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
        get '/request', { foo: 'foo' }
        expect(last_response.body).to eq('foo')
      end
    end

    context '定义 path 参数' do
      def app
        Class.new(Meta::Application) do
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
        get '/request/foo'
        expect(last_response.body).to eq('foo')
      end
    end

    context '定义 header 参数' do
      def app
        Class.new(Meta::Application) do
          get '/request' do
            parameters do
              param 'X-Foo', type: 'string', in: 'header'
            end
            action do
              response.body = [parameters['X-Foo']]
            end
          end
        end
      end

      it '传递 parameters 成功' do
        get '/request', {}, { 'HTTP_X_FOO' => 'foo' }
        expect(last_response.body).to eq('foo')
      end
    end

    context '定义两级参数' do
      def app
        Class.new(Meta::Application) do
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

    context '定义三级参数' do
      def app
        Class.new(Meta::Application) do
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

  describe 'params' do
    context '定义两级参数' do
      def app
        Class.new(Meta::Application) do
          namespace '/foo' do
            params do
              param :foo, type: 'string'
            end

            post '/bar' do
              params do
                param :bar, type: 'string'
              end
              action do
                response.body = [params.to_json]
              end
            end
          end
        end
      end

      it '没有能够合并 request_body 的参数' do
        post '/foo/bar', JSON.generate(foo: 'foo', bar: 'bar'), { 'CONTENT_TYPE' => 'application/json' }
        expect(JSON.parse(last_response.body)).to eq({
          'foo' => 'foo',
          'bar' => 'bar'
        })
      end
    end
  end

  describe 'request_body' do
    context '使用 request_body' do
      def app
        Class.new(Meta::Application) do
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

    describe '解析 request_body 时传递 execution: 选项' do
      def app
        the_entity = Class.new(Meta::Entity) do
          property :foo, value: Proc.new { self.class.name }
        end

        Class.new(Meta::Application) do
          post '/request' do
            params do
              param :nesting, ref: the_entity
            end
            action do
              response.body = [params[:nesting][:foo]]
            end
          end
        end
      end

      specify do
        post '/request', JSON.generate('nesting' => { 'foo' => 'foo' }), { 'CONTENT_TYPE' => 'application/json' }
        expect(last_response.body).to eq('Meta::Execution')
      end
    end

    context '遇到 `required: true` 时' do
      def app
        entity = Class.new(Meta::Entity) do
          expose :foo
          expose :bar, required: true
        end

        Class.new(Meta::Application) do
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
        entity = Class.new(Meta::Entity) do
          expose :foo
          expose :bar, render: false
        end

        Class.new(Meta::Application) do
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
        entity = Class.new(Meta::Entity) do
          expose :foo, value: lambda { resolve_method }
        end

        Class.new(Meta::Application) do
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

  describe 'status' do
    context 'action 中未设置 response.status' do
      def app
        Class.new(Meta::Application) do
          get '/request' do
            status 201
            action {}
          end
        end
      end

      it '默认使用第一个 status' do
        get '/request'
        expect(last_response.status).to eq 201
      end
    end

    context '在 status 顶层设置选项' do
      def app
        Class.new(Meta::Application) do
          get '/request' do
            status 201, type: 'integer'
            action do
              render 'string'
            end
          end
        end
      end

      it '应用顶层选项' do
        expect {
          get '/request'
        }.to raise_error(Meta::Errors::RenderingInvalid)
      end
    end

    context '定义两级 status' do
      def app
        Class.new(Meta::Application) do
          namespace '/foo' do
            meta do
              status 200, type: 'integer'
            end
            get '/bar' do
              status 201, type: 'integer'
              action do
                response.status = 200
                render 'string'
              end
            end
          end
        end
      end

      it '父子级的 responses 定义合并' do
        expect { get '/foo/bar' }.to raise_error(Meta::Errors::RenderingInvalid)
      end
    end
  end
end
