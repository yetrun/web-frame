# frozen_string_literal: true

require 'spec_helper'

# Scope 的场景测试比较重要，统一放在这里
describe 'Scope 的场景测试' do
  context 'Locked scope in JsonSchema' do
    describe '基本使用' do
      it 'Scope 的基本使用' do
        entity_class = Class.new(Meta::Entity) do
          property :foo, scope: 'foo'
          property :bar, scope: 'bar'
        end
        schema = entity_class.locked(scope: 'foo').to_schema

        value = schema.filter({ 'foo' => 'foo', 'bar' => 'bar' })
        expect(value).to eq({ foo: 'foo' })
      end

      it 'Locked scope 不会递归到深层级' do
        entity_class = Class.new(Meta::Entity) do
          property :foo, scope: 'foo'
          property :nesting do
            property :foo2, scope: 'foo'
          end
        end
        schema = entity_class.locked(scope: 'foo').to_schema

        value = schema.filter({ 'foo' => 'foo', 'nesting' => { 'foo2' => 'foo2' } })
        expect(value).to eq({ foo: 'foo', nesting: { foo2: 'foo2' } })
      end

      it 'Locked scope 不会递归给 ref' do
        inner_entity_class = Class.new(Meta::Entity) do
          property :foo2, scope: 'foo'
        end
        entity_class = Class.new(Meta::Entity) do
          property :foo, scope: 'foo'
          property :nesting, ref: inner_entity_class
        end
        schema = entity_class.locked(scope: 'foo').to_schema

        value = schema.filter({ 'foo' => 'foo', 'nesting' => { 'foo2' => 'foo2' } })
        expect(value).to eq({ foo: 'foo', nesting: {} })
      end

      it 'Locked scope 会检查传递进来的参数，如果未在实体中定义，则会报错' do
        entity_class = Class.new(Meta::Entity) do
          property :foo, scope: 'foo'
          property :nesting do
            property :bar, scope: 'bar'
          end
        end
        expect { entity_class.locked(scope: 'foo').to_schema }.not_to raise_error
        expect { entity_class.locked(scope: 'bar').to_schema }.not_to raise_error
        expect { entity_class.locked(scope: 'far').to_schema }.to raise_error(ArgumentError)
      end
    end

    describe 'Scope 的组合锁定' do
      shared_examples '分组合测试 UserEntity' do
        it '分组合测试 UserEntity' do
          schemas_with_different_scopes = {
            'user_list' => user_entity.to_schema,
            'user_detail' => user_entity.locked(scope: 'detail').to_schema,
            'admin_list' => user_entity.locked(scope: 'admin').to_schema,
            'admin_detail' => user_entity.locked(scope: ['detail', 'admin']).to_schema
          }

          value = { 'id' => 1, 'name' => 'Jim', 'profile' => 'profile', 'password' => 'passwd' }
          expect( schemas_with_different_scopes['user_list'].filter(value) ).to eq({ id: 1, name: 'Jim' })
          expect( schemas_with_different_scopes['user_detail'].filter(value) ).to eq({ id: 1, name: 'Jim', profile: 'profile' })
          expect( schemas_with_different_scopes['admin_list'].filter(value) ).to eq({ id: 1, name: 'Jim', password: 'passwd' })
          expect( schemas_with_different_scopes['admin_detail'].filter(value) ).to eq({ id: 1, name: 'Jim', profile: 'profile', password: 'passwd' })
        end
      end

      context '使用 scope 选项' do
        let(:user_entity) do
          Class.new(Meta::Entity) do
            property :id
            property :name
            property :profile, scope: 'detail'
            property :password, scope: 'admin'
          end
        end

        include_examples '分组合测试 UserEntity'
      end

      context '使用 with_common_options' do
        let(:user_entity) do
          Class.new(Meta::Entity) do
            property :id
            property :name
            with_common_options scope: 'detail' do
              property :profile
            end
            scope 'admin' do
              property :password
            end
          end
        end

        include_examples '分组合测试 UserEntity'
      end
    end

    describe 'if: 动态块' do
      let(:entity_class) do
        Class.new(Meta::Entity) do
          property :foo, if: ->(object_value) { object_value['use_foo'] }
          property :bar, if: ->() { self == 'use_bar' }
        end
      end
      let(:schema) { entity_class.to_schema }

      it 'if 选项接受 object_value' do
        value = schema.filter({ 'foo' => 'foo', 'bar' => 'bar', 'use_foo' => true })
        expect(value).to eq({ foo: 'foo' })
      end

      it 'if 选项接受 execution' do
        value = schema.filter({ 'foo' => 'foo', 'bar' => 'bar', 'use_foo' => false }, execution: 'use_bar')
        expect(value).to eq({ bar: 'bar' })
      end
    end
  end

  context 'In API' do
    context '在 namespace 和 route 中定义 scope' do
      let(:entity_class) do
        Class.new(Meta::Entity) do
          property :foo, scope: '$foo'
          property :bar, scope: '$bar'
        end
      end

      def app
        the_entity_class = entity_class
        Class.new(Meta::Application) do
          meta do
            scope '$foo'
          end

          post '/request' do
            scope '$bar'

            params do
              param :nesting, required: true, ref: the_entity_class
            end
            action do
              response.body = [JSON.generate(params)]
            end
          end
        end
      end

      it '继承了上方的 scopes' do
        post '/request', JSON.generate(nesting: { foo: 'foo', bar: 'bar' }), { 'CONTENT_TYPE' => 'application/json' }
        expect(JSON.parse(last_response.body)['nesting']).to eq({ 'foo' => 'foo', 'bar' => 'bar' })
      end

      context '混合使用了 namespace 层的 scope 和 locked scope' do
        let(:entity_class) do
          Class.new(Meta::Entity) do
            property :foo, scope: '$foo'
            property :bar, scope: '$bar'
          end
        end

        def app
          the_entity_class = entity_class
          Class.new(Meta::Application) do
            meta do
              scope '$foo'
            end

            post '/request' do
              params do
                param :nesting, required: true, ref: the_entity_class.locked(scope: '$bar')
              end
              action do
                response.body = [JSON.generate(params)]
              end
            end
          end
        end

        it '混合了二者的 scope' do
          post '/request', JSON.generate(nesting: { foo: 'foo', bar: 'bar' }), { 'CONTENT_TYPE' => 'application/json' }
          expect(JSON.parse(last_response.body)['nesting']).to eq({ 'foo' => 'foo', 'bar' => 'bar' })
        end
      end

      context 'scope 未设定为全局的格式' do
        it '在 namespace 中定义会报错' do
          application = Class.new(Meta::Application)
          expect {
            application.meta do
              scope 'foo'
            end
          }.to raise_error(ArgumentError)
        end

        it '在 route 中定义会报错' do
          application = Class.new(Meta::Application)
          route = application.get
          expect {
            route.scope 'foo'
          }.to raise_error(ArgumentError)
        end
      end
    end
  end
end
