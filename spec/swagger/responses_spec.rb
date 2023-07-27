# frozen_string_literal: true

# Note: 响应实体的生成与参数的一致，所以这里不再做深层次的测试了

require 'spec_helper'

describe 'Meta::SwaggerDocUtil.generate' do
  context '简单生成文档的效果' do
    subject do
      doc = Meta::SwaggerDocUtil.generate(app)
      doc[:paths]['/user'][:get][:responses][200][:content]['application/json'][:schema]
    end

    def app
      Class.new(Meta::Application) do
        get '/user' do
          status(200) do
            expose :user, type: 'object' do
              expose :name, type: 'string'
              expose :age, type: 'integer'
            end
          end
        end
      end
    end

    specify do
      is_expected.to eq(
        type: 'object',
        properties: {
          user: {
            type: 'object',
            properties: {
              name: { type: 'string' },
              age: { type: 'integer' }
            }
          }
        }
      )
    end
  end

  # 因为 ObjectSchemaBuilder 没有 locked 方法，故而将测试放在这里比较合适
  xcontext '使用 `using: Entity - schema_name 用块解析`' do
    subject(:doc) do
      Meta::SwaggerDocUtil.generate(app)
    end

    subject(:schema) do
      doc[:paths]['/user'][:get][:responses][200][:content]['application/json'][:schema]
    end

    subject(:components) do
      doc[:components]
    end

    def app
      user_entity = Class.new(Meta::Entity) do
        p = proc do |locked_scope, stage|
          'UserEntity'
        end
        schema_name p

        property :name, type: 'string'
        property :age, type: 'integer', scope: 'a'
      end
      Class.new(Meta::Application) do
        get '/user' do
          status(200) do
            expose :user, using: user_entity
          end
        end
      end
    end

    it do
      expect(schema).to eq(
        type: 'object',
        properties: {
          user: {
            '$ref': '#/components/schemas/UserEntity'
          }
        }
      )
      expect(components[:schemas]['UserEntity']).to eq(
        type: 'object',
        properties: {
          name: { type: 'string' }
        }
      )
    end
  end

  context '使用 `using: Entity lock_scope`' do
    subject(:doc) do
      Meta::SwaggerDocUtil.generate(app)
    end

    subject(:schema) do
      doc[:paths]['/user'][:get][:responses][200][:content]['application/json'][:schema]
    end

    subject(:components) do
      doc[:components]
    end

    def app
      user_entity = Class.new(Meta::Entity) do
        schema_name 'UserEntity'

        property :foo
        property :bar, scope: 'bar'
        property :baz, scope: 'baz'
      end
      Class.new(Meta::Application) do
        get '/user' do
          status(200) do
            expose :user, using: user_entity.lock_scope('bar')
          end
        end
      end
    end

    it do
      expect(schema).to eq(
        type: 'object',
        properties: {
          user: {
            '$ref': '#/components/schemas/UserEntity__bar'
          }
        }
      )
      expect(components[:schemas]['UserEntity__bar']).to eq(
        type: 'object',
        properties: {
          foo: {},
          bar: {}
        }
      )
    end
  end

  context '使用 `using: Entity - 自动解析 schema_name`' do
    subject(:doc) do
      Meta::SwaggerDocUtil.generate(app)
    end

    subject(:schema) do
      doc[:paths]['/user'][:get][:responses][200][:content]['application/json'][:schema]
    end

    subject(:components) do
      doc[:components]
    end

    class UserEntity < Meta::Entity
      property :name, type: 'string'
      property :age, type: 'integer'
    end

    def app
      Class.new(Meta::Application) do
        get '/user' do
          status(200) do
            expose :user, using: UserEntity
          end
        end
      end
    end

    it do
      expect(schema).to eq(
        type: 'object',
        properties: {
          user: {
            '$ref': '#/components/schemas/UserEntity'
          }
        }
      )
      expect(components[:schemas]['UserEntity']).to eq(
        type: 'object',
        properties: {
          name: { type: 'string' },
          age: { type: 'integer' }
        }
      )
    end
  end

  context '使用 `using: Entity - 自动解析 schema_name & lock_scope`' do
    subject(:doc) do
      Meta::SwaggerDocUtil.generate(app)
    end

    subject(:schema) do
      doc[:paths]['/user'][:get][:responses][200][:content]['application/json'][:schema]
    end

    subject(:components) do
      doc[:components]
    end

    class TheEntity < Meta::Entity
      property :foo
      property :bar, scope: 'bar'
      property :baz, scope: 'baz'
    end

    def app
      Class.new(Meta::Application) do
        get '/user' do
          status(200) do
            expose :user, using: TheEntity.lock_scope('bar')
          end
        end
      end
    end

    it do
      expect(schema).to eq(
        type: 'object',
        properties: {
          user: {
            '$ref': '#/components/schemas/TheEntity__bar'
          }
        }
      )
      expect(components[:schemas]['TheEntity__bar']).to eq(
        type: 'object',
        properties: {
          foo: {},
          bar: {}
        }
      )
    end
  end

  xcontext '使用 `using: Entity` - 内部引用自身' do
    subject(:doc) do
      Meta::SwaggerDocUtil.generate(app)
    end

    subject(:schema) do
      doc[:paths]['/user'][:get][:responses][200][:content]['application/json'][:schema]
    end

    subject(:components) do
      doc[:components]
    end

    let(:entity) do
      entity = Class.new(Meta::Entity) do
        schema_name 'TheEntity'
      end
      entity.class_eval do
        property :self, using: entity
      end
      entity
    end

    def app
      the_entity = entity
      Class.new(Meta::Application) do
        get '/user' do
          status(200) do
            expose :the_entity, using: the_entity
          end
        end
      end
    end

    it 'user 属性返回引用' do
      expect(schema).to eq(
        type: 'object',
        properties: {
          the_entity: {
            '$ref': '#/components/schemas/TheEntity'
          }
        }
      )
    end

    it 'UserEntity 被添加进 schemas' do
      expect(components[:schemas]['TheEntity']).to eq(
        type: 'object',
        properties: {
          self: {
            '$ref': '#/components/schemas/TheEntity'
          }
        }
      )
    end
  end

  context '未提供 status 宏时' do
    subject(:doc) do
      Meta::SwaggerDocUtil.generate(app)
    end

    subject(:responses) do
      doc[:paths]['/request'][:get][:responses]
    end

    def app
      Class.new(Meta::Application) do
        get '/request' do
          status 204
          action do
            response.status = 204
          end
        end
      end
    end

    it '生成状态码为 204 的文档' do
      expect(responses).to have_key(204)
    end

    it '成功调用请求' do
      get '/request'

      expect(last_response.status).to eq 204
    end
  end
end
