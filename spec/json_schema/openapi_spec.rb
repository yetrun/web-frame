# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/json_schema/schemas'

describe 'openapi' do
  it '生成对象 Schema 的文档' do
    schema = Dain::JsonSchema::SchemaBuilderTool.build do
      param :user, description: '用户' do
        param :name
        param :age
      end
    end.to_schema

    expect(schema.to_schema_doc(stage: :param)).to eq(
      type: 'object',
      properties: {
        user: {
          type: 'object',
          description: '用户',
          properties: {
            name: {},
            age: {}
          }
        }
      }
    )
  end

  context 'using: Entity' do
    let(:user_entity) do
      Class.new(Dain::Entity) do
        schema_name param: 'UserParams', render: 'UserEntity'

        property :name
        property :age
      end
    end

    let(:schema) do
      the_entity = user_entity
      Dain::JsonSchema::SchemaBuilderTool.build do
        param :user, using: the_entity
      end.to_schema
    end

    it '参数文档返回引用的效果' do
      schemas = {}
      doc = schema.to_schema_doc(stage: :param, schemas: schemas)

      expect(doc).to eq(
        type: 'object',
        properties: {
          user: {
            '$ref': '#/components/schemas/UserParams'
          }
        }
      )
      expect(schemas['UserParams']).to eq(
        type: 'object',
        properties: {
          age: {},
          name: {}
        }
      )
    end

    it '实体文档返回引用的效果' do
      schemas = {}
      doc = schema.to_schema_doc(stage: :render, schemas: schemas)

      expect(doc).to eq(
        type: 'object',
        properties: {
          user: {
            '$ref': '#/components/schemas/UserEntity'
          }
        }
      )
      expect(schemas['UserEntity']).to eq(
        type: 'object',
        properties: {
          age: {},
          name: {}
        }
      )
    end
  end

  describe 'requires' do
    it 'required 属性生成 requires 文档' do
      schema = Dain::JsonSchema::SchemaBuilderTool.build do
        param :user, description: '用户' do
          param :name, required: true
          param :age
        end
      end.to_schema

      expect(schema.to_schema_doc(stage: :param)).to eq(
        type: 'object',
        properties: {
          user: {
            type: 'object',
            description: '用户',
            properties: {
              name: {},
              age: {}
            },
            requires: [:name]
          }
        }
      )
    end
  end

  describe 'enum' do
    it 'allowable 选项可以生成 enum 部分' do
      schema = Dain::JsonSchema::SchemaBuilderTool.build do
        param :user, description: '用户' do
          param :name, allowable: %w[Jim Jack James]
          param :age
        end
      end.to_schema

      expect(schema.to_schema_doc(stage: :param)).to eq(
        type: 'object',
        properties: {
          user: {
            type: 'object',
            description: '用户',
            properties: {
              name: {
                enum: %w[Jim Jack James]
              },
              age: {}
            }
          }
        }
      )
    end
  end
end
