# frozen_string_literal: true

require 'spec_helper'

describe 'Route Builder' do
  include Rack::Test::Methods

  describe '一个带有所有基本要素的 DSL 实例' do
    def app
      article_entity = Class.new(Meta::Entity) do
        property :title
        property :content
      end

      Class.new(Meta::Application) do
        route '/article', :put do
          title '更新一篇新的文章'
          params do
            param :article, using: article_entity
          end
          status 200 do
            expose :article, using: article_entity
          end
          action do
            article = {
              :'title' => params[:article][:title].capitalize,
              :'content' => params[:article][:content].capitalize,
            }
            render('article' => article)
          end
        end
      end
    end

    specify do
      put '/article', JSON.generate('article' => { 'title' => 'title', 'content' => 'content' }), { 'CONTENT_TYPE' => 'application/json' }
      expect(JSON.parse(last_response.body)['article']).to eq('title' => 'Title', 'content' => 'Content')
    end
  end

  describe 'namespace' do
    context '简单调用' do
      def app
        Class.new(Meta::Application) do
          namespace '/nesting' do
            route '/foo', :get do
              action do
                response.body = ['foo']
              end
            end

            route '/bar', :get do
              action do
                response.body = ['bar']
              end
            end
          end
        end
      end

      specify do
        get '/nesting/foo'
        expect(last_response.body).to eq('foo')

        get '/nesting/bar'
        expect(last_response.body).to eq('bar')
      end
    end

    context '带路径参数' do
      def app
        Class.new(Meta::Application) do
          namespace '/nesting/:key' do
            before do
              @key = request.params['key']
            end

            params do
              param :key, type: 'string'
            end

            route '/foo', :get do
              action do
                response.body = "foo: #{@key}"
              end
            end

            route '/bar', :get do
              action do
                response.body = "bar: #{@key}"
              end
            end
          end
        end
      end

      specify do
        get '/nesting/one/foo'
        expect(last_response.body).to eq('foo: one')

        get '/nesting/two/bar'
        expect(last_response.body).to eq('bar: two')
      end
    end

    describe '定义共同 meta' do
      context '定义共同响应值' do
        def app
          Class.new(Meta::Application) do
            namespace '/nesting' do
              meta do
                status(200, 201) { expose :foo }
              end

              route '/foo', :post do
                action { render('foo' => 'foo', 'bar' => 'bar') }
              end

              route '/bar', :post do
                status(200, 201) { expose :bar }
                action { render('foo' => 'foo', 'bar' => 'bar') }
              end
            end
          end
        end

        specify do
          post '/nesting/foo', JSON.generate(foo: 'foo', bar: 'bar'), { 'CONTENT_TYPE' => 'application/json' }
          expect(JSON.parse(last_response.body)).to eq('foo' => 'foo')

          post '/nesting/bar', JSON.generate(foo: 'foo', bar: 'bar'), { 'CONTENT_TYPE' => 'application/json' }
          expect(JSON.parse(last_response.body)).to eq('bar' => 'bar')
        end
      end

      # 其他的诸如 tags、title、description 与上两个同，不再测试
    end
  end

  describe 'apply' do
    def app
      foo = Class.new(Meta::Application) do
        route '/foo', :get do
          action do
            response.body = ['foo']
          end
        end
      end

      bar = Class.new(Meta::Application) do
        route '/bar', :get do
          action do
            response.body = ['bar']
          end
        end
      end

      Class.new(Meta::Application) do
        apply foo, tags: ['Foo']
        apply bar, tags: ['Bar']
      end
    end

    it '响应请求' do
      get '/foo'
      expect(last_response.body).to eq('foo')

      get '/bar'
      expect(last_response.body).to eq('bar')
    end

    it '生成对应 tags 的文档' do
      doc = Meta::SwaggerDocUtil.generate(app)

      expect(doc[:paths]['/foo'][:get][:tags]).to eq(['Foo'])
      expect(doc[:paths]['/bar'][:get][:tags]).to eq(['Bar'])
    end
  end

  describe 'namespace 和 apply 结合' do
    def app
      foo = Class.new(Meta::Application) do
        route '/foo', :get do
          action do
            response.body = ['foo']
          end
        end
      end

      bar = Class.new(Meta::Application) do
        route '/bar', :get do
          action do
            response.body = ['bar']
          end
        end
      end

      Class.new(Meta::Application) do
        namespace '/nesting' do
          apply foo, tags: ['Foo']
          apply bar, tags: ['Bar']
        end
      end
    end

    it '响应请求' do
      get '/nesting/foo'
      expect(last_response.body).to eq('foo')

      get '/nesting/bar'
      expect(last_response.body).to eq('bar')
    end

    it '生成对应 tags 的文档' do
      doc = Meta::SwaggerDocUtil.generate(app)

      expect(doc[:paths]['/nesting/foo'][:get][:tags]).to eq(['Foo'])
      expect(doc[:paths]['/nesting/bar'][:get][:tags]).to eq(['Bar'])
    end
  end

  describe '共享模块' do
    def app
      mod_foo = Module.new do
        def foo; 'foo' end
      end
      mod_bar = Module.new do
        def bar; 'bar' end
      end

      Class.new(Meta::Application) do
        shared mod_foo, mod_bar do
          def ok; 'ok' end
        end

        route '/foo', :get do
          action do
            foo; bar; ok
          end
        end
      end
    end

    it '模块内的方法被成功引入' do
      expect { get '/foo' }.not_to raise_error
    end
  end

  describe '路径' do
    context '访问根路由 `/`' do
      def app
        Class.new(Meta::Application) do
          get '/' do
            action do
              response.body = ['foo']
            end
          end
        end
      end

      specify do
        get '/'
        expect(last_response.status).to eq(200)
      end
    end

    context '内部使用根路径 `/`' do
      def app
        Class.new(Meta::Application) do
          namespace '/nesting' do
            get '/' do
              action do
                response.body = ['foo']
              end
            end
          end
        end
      end

      specify do
        get '/nesting'
        expect(last_response.body).to eq('foo')
      end
    end

    context '内部不使用 `/` 前缀' do
      def app
        Class.new(Meta::Application) do
          namespace '/nesting' do
            get 'foo' do
              action do
                response.body = ['foo']
              end
            end
          end
        end
      end

      specify do
        get '/nesting/foo'
        expect(last_response.body).to eq('foo')
      end
    end

    context '内部使用 `/` 后缀' do
      def app
        Class.new(Meta::Application) do
          namespace '/nesting' do
            get '/foo/' do
              action do
                response.body = ['foo']
              end
            end
          end
        end
      end

      specify do
        get '/nesting/foo'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('foo')
      end
    end
  end
end
