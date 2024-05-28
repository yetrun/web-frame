# frozen_string_literal: true

require 'spec_helper'

describe 'schema#to_schema_doc' do
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

  describe 'user options' do
    describe 'scope: 选项' do
      it 'scope 过滤掉不匹配的字段' do
        schema = Meta::JsonSchema::SchemaBuilderTool.build do
          property :foo, scope: 'foo' do
            param :foo2, scope: 'foo'
            param :bar2, scope: 'bar'
          end
          property :bar, scope: 'bar'
        end
        expect(schema.to_schema_doc(scope: 'foo')).to eq(
          type: 'object',
          properties: {
            foo: {
              type: 'object',
              properties: {
                foo2: {}
              }
            }
          }
        )
      end

      it 'scope: 选项对 ref 的影响' do
        foo_entity = Class.new(Meta::Entity) do
          schema_name 'FooEntity'

          property :foo2, scope: 'foo'
        end
        bar_entity = Class.new(Meta::Entity) do
          schema_name 'BarEntity'

          property :bar2, scope: 'bar'
        end
        baz_entity = Class.new(Meta::Entity) do
          schema_name 'BazEntity'

          property :foo, ref: foo_entity
          property :bar, ref: bar_entity
        end

        schema = Meta::JsonSchema::SchemaBuilderTool.build do
          property :foo, ref: foo_entity
          property :bar, ref: bar_entity
          property :baz, ref: baz_entity
        end
        schemas = {}
        schema.to_schema_doc(scope: ['foo', 'bar', 'baz'], schema_docs_mapping: schemas, stage: :render)

        expect(schemas.keys).to eq(['FooEntity__foo', 'BarEntity__bar', 'BazEntity__foo__bar'])
      end

      context 'ref: 引用自身' do
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

        it '正确生成 schema 文档不报错' do
          entity.to_schema.to_schema_doc(schema_docs_mapping: {}, stage: :render)
        end
      end
    end
  end

  describe 'schema options' do
    context 'using' do
      context 'using: Entity' do
        let(:user_entity) do
          Class.new(Meta::Entity) do
            schema_name 'UserEntity'

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
            @doc = schema.to_schema_doc(stage: :param, schema_docs_mapping: @schemas)
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
            @doc = schema.to_schema_doc(stage: :render, schema_docs_mapping: @schemas)
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
              schema_name 'One'
              property :one
            end
            entity_two = Class.new(Meta::Entity) do
              schema_name 'Two'
              property :two
            end

            Meta::JsonSchema::SchemaBuilderTool.build do
              param :nested, dynamic_ref: { one_of: [entity_one, entity_two] }
            end.to_schema
          end

          it '文档返回了参数的引用' do
            schemas = {}
            doc = schema.to_schema_doc(stage: :render, schema_docs_mapping: schemas)

            expect(doc).to eq(
              type: 'object',
              properties: {
                nested: {
                  type: 'object',
                  oneOf: [
                    {
                      '$ref': '#/components/schemas/OneEntity'
                    },
                    {
                      '$ref': '#/components/schemas/TwoEntity'
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
            doc = schema.to_schema_doc(stage: :render, schema_docs_mapping: schemas)

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

  describe 'ObjectSchemaBuilder methods' do
    describe 'add_scope' do
      it '过滤掉 scope 不匹配的字段' do
        schema = Meta::JsonSchema::ObjectSchemaBuilder.new do
          param :foo
          param :bar, scope: 'bar'
          param :baz, scope: 'baz'
        end.locked(scope: 'bar').to_schema

        expect(schema.to_schema_doc(stage: :param)).to eq(
          type: 'object',
          properties: {
            foo: {},
            bar: {}
          }
        )
      end

      context '深层嵌套' do
        it '过滤掉 scope 不匹配的字段' do
          schema = Meta::JsonSchema::ObjectSchemaBuilder.new do
            param :foo do
              param :bar, scope: 'bar'
              param :baz, scope: 'baz'
            end
            param :bar, scope: 'bar'
            param :baz, scope: 'baz'
          end.locked(scope: 'bar').to_schema

          expect(schema.to_schema_doc(stage: :param)).to eq(
            type: 'object',
            properties: {
              foo: {
                type: 'object',
                properties: {
                  bar: {}
                }
              },
              bar: {}
            }
          )
        end
      end
    end
  end
end
