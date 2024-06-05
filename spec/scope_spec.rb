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
    end

    context '深层定义' do
      context '生层级定义相同的 scope' do
        it '作用到深层级' do
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

        xit '不会作用给 ref' do
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
      end

      context '深层级定义不同的 scope' do
        let(:user_entity) do
          Class.new(Meta::Entity) do
            property :profile, scope: 'admin' do
              property :age
              property :brief, scope: 'detail'
            end
          end
        end

        let(:value) do
          { 'profile' => { 'age' => 18, 'brief' => 'brief' } }
        end

        it '传递两个 scope 时返回所有字段' do
          schema = user_entity.locked(scope: ['admin', 'detail']).to_schema
          expect( schema.filter(value)[:profile] ).to eq({ age: 18, brief: 'brief' })
        end

        it '仅传递外层 scope 时返回部分内层字段' do
          schema = user_entity.locked(scope: ['admin']).to_schema
          expect( schema.filter(value)[:profile] ).to eq({ age: 18 })
        end

        it '仅传递内层 scope 时不返回所有字段' do
          schema = user_entity.locked(scope: ['detail']).to_schema
          expect( schema.filter(value)[:profile] ).to eq(nil)
        end
      end

      xit '调用 lock_scope 时检查传递进来的 scope 参数' do
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

    context '定义和提供多个 scope' do
      let(:user_entity) do
        Class.new(Meta::Entity) do
          property :xxx, scope: %w[foo bar]
        end
      end

      let(:value) do
        { 'xxx' => 'xxx' }
      end

      describe 'lock_scope' do
        it '调用 lock_scope 时提供两个 scope 能成功返回字段' do
          schema = user_entity.locked(scope: %w[foo bar]).to_schema
          expect( schema.filter(value).keys ).to be_any
        end

        it '调用 lock_scope 时仅提供一个 scope 也能成功返回字段' do
          schema = user_entity.locked(scope: ['foo']).to_schema
          expect( schema.filter(value).keys ).to be_any
        end
      end

      describe '提供 scope' do
        it '调用 filter 时提供两个 scope 能成功返回字段' do
          schema = user_entity.to_schema(scope: %w[foo bar])
          expect( schema.filter(value).keys ).to be_any

          schema = user_entity.to_schema(scope: %w[foo bar])
          expect( schema.filter(value).keys ).to be_any
        end

        it '调用 filter 时仅提供一个 scope 也能成功返回字段' do
          schema = user_entity.to_schema(scope: ['foo'])
          expect( schema.filter(value).keys ).to be_any

          schema = user_entity.to_schema(scope: %w[foo])
          expect( schema.filter(value).keys ).to be_any
        end
      end
    end

    # `with_common_options scope:` 应当有特殊的效果，这里的测试暂时通不过
    context 'with_common_options' do
      let(:user_entity) do
        Class.new(Meta::Entity) do
          # 关于 param、render 内部选项的合并问题暂不考虑
          scope 'admin' do
            property :age
            property :brief, scope: 'detail'
          end
        end
      end

      let(:value) do
        { 'age' => 18, 'brief' => 'brief' }
      end

      it '调用 lock_scope 时提供两层 scope 能成功返回全部字段' do
        schema = user_entity.locked(scope: ['admin', 'detail']).to_schema
        expect( schema.filter(value).keys ).to eq([:age, :brief])
      end

      it '调用 lock_scope 时仅提供外层的 scope 只会返回部分字段' do
        schema = user_entity.locked(scope: ['admin']).to_schema
        expect( schema.filter(value).keys ).to eq([:age])
      end

      it '调用 lock_scope 时仅提供内层的 scope 不会返回字段' do
        schema = user_entity.locked(scope: ['detail']).to_schema
        expect( schema.filter(value).keys ).to eq([])
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
          property :foo, scope: 'foo'
          property :bar, scope: 'bar'
        end
      end

      def app
        the_entity_class = entity_class
        Class.new(Meta::Application) do
          meta do
            scope 'foo'
          end

          post '/request' do
            scope 'bar'

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
            property :foo, scope: 'foo'
            property :bar, scope: 'bar'
          end
        end

        def app
          the_entity_class = entity_class
          Class.new(Meta::Application) do
            meta do
              scope 'foo'
            end

            post '/request' do
              params do
                param :nesting, required: true, ref: the_entity_class.locked(scope: 'bar')
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
        xit '在 namespace 中定义会报错' do
          application = Class.new(Meta::Application)
          expect {
            application.meta do
              scope 'foo'
            end
          }.to raise_error(ArgumentError)
        end

        xit '在 route 中定义会报错' do
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
