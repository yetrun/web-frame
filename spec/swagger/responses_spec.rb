# frozen_string_literal: true

# Note: 响应实体的生成与参数的一致，所以这里不再做深层次的测试了

require 'spec_helper'
require_relative '../../lib/swagger_doc'

describe 'Dain::SwaggerDocUtil.generate' do
  context '简单生成文档的效果' do
    subject do
      doc = Dain::SwaggerDocUtil.generate(app)
      doc[:paths]['/user'][:get][:responses][200][:content]['application/json'][:schema]
    end

    def app
      Class.new(Dain::Application) do
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
  context '使用 `using: Entity - schema_name 用块解析`' do
    subject(:doc) do
      Dain::SwaggerDocUtil.generate(app)
    end

    subject(:schema) do
      doc[:paths]['/user'][:get][:responses][200][:content]['application/json'][:schema]
    end

    subject(:components) do
      doc[:components]
    end

    def app
      user_entity = Class.new(Dain::Entity) do
        p = proc do
          {
            param: 'UserEntity',
            render: 'UserEntity'
          }
        end
        schema_name p

        property :name, type: 'string'
        property :age, type: 'integer'
      end
      Class.new(Dain::Application) do
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
          name: { type: 'string' },
          age: { type: 'integer' }
        }
      )
    end
  end

  context '使用 `using: Entity - schema_name 用块解析 & lock_scope`' do
    subject(:doc) do
      Dain::SwaggerDocUtil.generate(app)
    end

    subject(:schema) do
      doc[:paths]['/user'][:get][:responses][200][:content]['application/json'][:schema]
    end

    subject(:components) do
      doc[:components]
    end

    def app
      user_entity = Class.new(Dain::Entity) do
        p = proc do |locked_scope|
          {
            param: "UserParams#{locked_scope}",
            render: "UserEntity_#{locked_scope}"
          }
        end
        schema_name p

        property :foo
        property :bar, scope: 'bar'
        property :baz, scope: 'baz'
      end
      Class.new(Dain::Application) do
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
            '$ref': '#/components/schemas/UserEntity_bar'
          }
        }
      )
      expect(components[:schemas]['UserEntity_bar']).to eq(
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
      Dain::SwaggerDocUtil.generate(app)
    end

    subject(:schema) do
      doc[:paths]['/user'][:get][:responses][200][:content]['application/json'][:schema]
    end

    subject(:components) do
      doc[:components]
    end

    class UserEntity < Dain::Entity
      property :name, type: 'string'
      property :age, type: 'integer'
    end

    def app
      # TODO: 测试结束后移除常量名
      Class.new(Dain::Application) do
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
      Dain::SwaggerDocUtil.generate(app)
    end

    subject(:schema) do
      doc[:paths]['/user'][:get][:responses][200][:content]['application/json'][:schema]
    end

    subject(:components) do
      doc[:components]
    end

    class TheEntity < Dain::Entity
      property :foo
      property :bar, scope: 'bar'
      property :baz, scope: 'baz'
    end

    def app
      Class.new(Dain::Application) do
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
            '$ref': '#/components/schemas/TheEntity_bar'
          }
        }
      )
      expect(components[:schemas]['TheEntity_bar']).to eq(
        type: 'object',
        properties: {
          foo: {},
          bar: {}
        }
      )
    end
  end

  context '使用 `using: Entity` - 内部引用自身' do
    subject(:doc) do
      Dain::SwaggerDocUtil.generate(app)
    end

    subject(:schema) do
      doc[:paths]['/user'][:get][:responses][200][:content]['application/json'][:schema]
    end

    subject(:components) do
      doc[:components]
    end

    let(:entity) do
      entity = Class.new(Dain::Entity) do
        schema_name 'TheEntity'
      end
      entity.class_eval do
        property :self, using: entity
      end
      entity
    end

    def app
      the_entity = entity
      Class.new(Dain::Application) do
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
end
