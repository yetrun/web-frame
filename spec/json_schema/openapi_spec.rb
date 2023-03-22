# frozen_string_literal: true

require 'spec_helper'

describe 'openapi' do
  it '生成对象 Schema 的文档' do
    schema = Meta::JsonSchema::SchemaBuilderTool.build do
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

  context 'using' do
    context 'using: Entity' do
      let(:user_entity) do
        Class.new(Meta::Entity) do
          schema_name param: 'UserParams', render: 'UserEntity'

          property :name
          property :age
        end
      end

      let(:schema) do
        the_entity = user_entity
        Meta::JsonSchema::SchemaBuilderTool.build do
          param :user, using: the_entity
        end.to_schema
      end

      describe '参数文档的效果' do
        before {
          @schemas = {}
          @doc = schema.to_schema_doc(stage: :param, schemas: @schemas)
        }

        it '参数文档返回引用的效果' do
          expect(@doc).to eq(
            type: 'object',
            properties: {
              user: {
                '$ref': '#/components/schemas/UserParams'
              }
            }
          )
        end

        it '详细的实体定义写到 schemas 中' do
          expect(@schemas['UserParams']).to eq(
            type: 'object',
            properties: {
              age: {},
              name: {}
            }
          )
        end
      end

      describe '实体文档的效果' do
        before {
          @schemas = {}
          @doc = schema.to_schema_doc(stage: :render, schemas: @schemas)
        }

        it '渲染实体返回引用的效果' do
          expect(@doc).to eq(
            type: 'object',
            properties: {
              user: {
                '$ref': '#/components/schemas/UserEntity'
              }
            }
          )
        end

        it '详细的实体定义写到 schemas 中' do
          expect(@schemas['UserEntity']).to eq(
            type: 'object',
            properties: {
              age: {},
              name: {}
            }
          )
        end
      end
    end

    context 'dynamic_ref' do
      context '选项中写有 one_of' do
        let(:schema) do
          entity_one = Class.new(Meta::Entity) do
            schema_name param: 'EntityOne', render: 'EntityOne'
            property :one
          end
          entity_two = Class.new(Meta::Entity) do
            schema_name param: 'EntityTwo', render: 'EntityTwo'
            property :two
          end

          Meta::JsonSchema::SchemaBuilderTool.build do
            param :nested, dynamic_ref: { one_of: [entity_one, entity_two] }
          end.to_schema
        end

        it '文档返回了参数的引用' do
          schemas = {}
          doc = schema.to_schema_doc(stage: :render, schemas: schemas)

          expect(doc).to eq(
            type: 'object',
            properties: {
              nested: {
                type: 'object',
                oneOf: [
                  {
                    '$ref': '#/components/schemas/EntityOne'
                  },
                  {
                    '$ref': '#/components/schemas/EntityTwo'
                  }
                ]
              }
            }
          )
        end
      end

      context '选项中不包含 one_of' do
        let(:schema) do
          Meta::JsonSchema::SchemaBuilderTool.build do
            param :nested, dynamic_ref: {}
          end.to_schema
        end

        it '文档仅返回 type: "object"' do
          schemas = {}
          doc = schema.to_schema_doc(stage: :render, schemas: schemas)

          expect(doc).to eq(
            type: 'object',
            properties: {
              nested: {
                type: 'object'
              }
            }
          )
        end
      end
    end
  end

  context 'locked scope' do
    it '过滤掉 scope 不匹配的参数' do
      schema = Meta::JsonSchema::ObjectSchemaBuilder.new do
        param :foo
        param :bar, scope: 'bar'
        param :baz, scope: 'baz'
      end.to_schema(scope: 'bar')

      expect(schema.to_schema_doc(stage: :param)).to eq(
        type: 'object',
        properties: {
          foo: {},
          bar: {}
        }
      )
    end
  end

  describe 'requires' do
    it 'required 属性生成 requires 文档' do
      schema = Meta::JsonSchema::SchemaBuilderTool.build do
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
            required: [:name]
          }
        }
      )
    end
  end

  describe 'enum' do
    it 'allowable 选项可以生成 enum 部分' do
      schema = Meta::JsonSchema::SchemaBuilderTool.build do
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
