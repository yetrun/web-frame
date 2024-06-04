# frozen_string_literal: true

require 'spec_helper'

describe 'Scope In API' do
  before(:context) do
    module Test
      Scopes = Module.new

      Scopes::Foo = Class.new(Meta::Scope)
      Scopes::Bar = Class.new(Meta::Scope)
      Scopes::Baz = Class.new(Meta::Scope)

      Scopes::User = Class.new(Meta::Scope)
      Scopes::Broker = Class.new(User)
      Scopes::Admin = Class.new(Broker)
    end
  end

  context '在 namespace 和 route 中定义 scope' do
    let(:entity_class) do
      Class.new(Meta::Entity) do
        property :foo, scope: Test::Scopes::Foo
        property :bar, scope: Test::Scopes::Bar
      end
    end

    def app
      the_entity_class = entity_class
      Class.new(Meta::Application) do
        meta do
          scope Test::Scopes::Foo
        end

        post '/request' do
          scope Test::Scopes::Bar

          params do
            param :nesting, required: true, ref: the_entity_class
          end
          action do
            response.body = [JSON.generate(params)]
          end
        end
      end
    end

    it 'namespace 和 route 定义的 scopes 会联合作为运行时 scope 选项' do
      post '/request', JSON.generate(nesting: { foo: 'foo', bar: 'bar' }), { 'CONTENT_TYPE' => 'application/json' }
      expect(JSON.parse(last_response.body)['nesting']).to eq({ 'foo' => 'foo', 'bar' => 'bar' })
    end
  end

  describe '生成文档的基本考量' do
    let(:entity_class) do
      Class.new(Meta::Entity) do
        schema_name 'Some'

        property :foo, scope: Test::Scopes::Foo
        property :nesting do
          property :bar, scope: Test::Scopes::Bar
        end
      end
    end

    def app
      the_entity_class = entity_class
      Class.new(Meta::Application) do
        post '/request' do
          status 200 do
            expose :nesting, required: true, ref: the_entity_class.locked(scope: [Test::Scopes::Bar, Test::Scopes::Baz])
          end
        end
      end
    end

    it '考虑递归、lock_scope 传递多余的 scope' do
      doc = app.to_swagger_doc
      name, schema = doc[:components][:schemas].first
      expect(name).to include('Bar')
      expect(name).not_to include('Foo')
      expect(name).not_to include('Baz')
    end
  end

  context '考虑 Scope 具有继承的情况' do
    let(:entity_class) do
      Class.new(Meta::Entity) do
        schema_name 'Some'

        property :admin, scope: Test::Scopes::Admin
      end
    end

    context 'lock_scope 不包含本身的 scope' do
      def app
        the_entity_class = entity_class
        Class.new(Meta::Application) do
          post '/request' do
            status 200 do
              expose :nesting, required: true, ref: the_entity_class.locked(scope: [Test::Scopes::Foo, Test::Scopes::User, Test::Scopes::Broker])
            end
            action do
              response.body = [JSON.generate(nesting: { admin: 'admin', foo: 'foo' })]
            end
          end
        end
      end

      it '生成的 schema name 中只包含本身的 scope 名称' do
        doc = app.to_swagger_doc
        name, schema = doc[:components][:schemas].first
        expect(name).not_to include('Foo')
        expect(name).not_to include('User')
        expect(name).not_to include('Broker')
        expect(name).to include('Admin')
      end

      it '接口运行正常' do
        post '/request', JSON.generate(nesting: { admin: 'admin' }), { 'CONTENT_TYPE' => 'application/json' }
        expect(JSON.parse(last_response.body)['nesting']).to eq({ 'admin' => 'admin' })
      end
    end

    context 'lock_scope 传递本身的 scope' do
      def app
        the_entity_class = entity_class
        Class.new(Meta::Application) do
          post '/request' do
            status 200 do
              expose :nesting, required: true, ref: the_entity_class.locked(scope: [Test::Scopes::Foo, Test::Scopes::Admin])
            end
            action do
              response.body = [JSON.generate(nesting: { admin: 'admin', foo: 'foo' })]
            end
          end
        end
      end

      it '生成的 schema name 中只包含本身的 scope 名称' do
        doc = app.to_swagger_doc
        name, schema = doc[:components][:schemas].first
        expect(name).not_to include('Foo')
        expect(name).not_to include('User')
        expect(name).not_to include('Broker')
        expect(name).to include('Admin')
      end

      it '接口运行正常' do
        post '/request', JSON.generate(nesting: { admin: 'admin' }), { 'CONTENT_TYPE' => 'application/json' }
        expect(JSON.parse(last_response.body)['nesting']).to eq({ 'admin' => 'admin' })
      end
    end
  end
end
