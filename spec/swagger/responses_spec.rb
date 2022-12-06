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

  context '使用 `using: Entity`' do
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
        schema_name 'UserEntity'

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
end
