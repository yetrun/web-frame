# frozen_string_literal: true

require 'spec_helper'

# 针对 Scope 的文档测试，复制一份一模一样的
describe 'Scope 的场景测试' do
  context 'Locked scope in JsonSchema' do
    describe '基本使用' do
      it 'Scope 的基本使用' do
        entity_class = Class.new(Meta::Entity) do
          property :foo, scope: 'foo'
          property :bar, scope: 'bar'
        end
        schema = entity_class.locked(scope: 'foo').to_schema
        expect(schema.to_schema_doc[:properties].keys).to eq([:foo])

        # TODO: 没有提示也没有报错
        # schema.to_swagger_doc
      end

      it 'Locked scope 会递归到深层级' do
        entity_class = Class.new(Meta::Entity) do
          property :foo, scope: 'foo'
          property :nesting do
            property :foo2, scope: 'foo'
          end
        end
        schema = entity_class.locked(scope: 'foo').to_schema

        expect(
          schema.to_schema_doc
        ).to match(
               a_hash_including(
                 properties: {
                   foo: a_kind_of(Hash),
                   nesting: a_hash_including(
                     properties: { foo2: a_kind_of(Hash) }
                   )
                 }
               )
             )
      end

      it 'Locked scope 不会递归给 ref' do
        inner_entity_class = Class.new(Meta::Entity) do
          schema_name 'Inner'

          property :foo2, scope: 'foo'
        end
        entity_class = Class.new(Meta::Entity) do
          schema_name 'Outer'

          property :foo, scope: 'foo'
          property :nesting, ref: inner_entity_class
        end
        schema = entity_class.locked(scope: 'foo').to_schema

        schema_docs_mapping = {}
        doc = schema.to_schema_doc(stage: :render, schema_docs_mapping: schema_docs_mapping)
        expect(doc).to match(
                         a_hash_including(
                           properties: {
                             foo: a_kind_of(Hash),
                             nesting: {
                               '$ref': a_kind_of(String)
                             }
                           }
                         )
                       )
        expect(schema_docs_mapping.first[1][:properties].keys).to eq([:foo2])
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

          expect(schemas_with_different_scopes['user_list'].to_schema_doc[:properties].keys).to eq([:id, :name])
          expect(schemas_with_different_scopes['user_detail'].to_schema_doc[:properties].keys).to eq([:id, :name, :profile])
          expect(schemas_with_different_scopes['admin_list'].to_schema_doc[:properties].keys).to eq([:id, :name, :password])
          expect(schemas_with_different_scopes['admin_detail'].to_schema_doc[:properties].keys).to eq([:id, :name, :profile, :password])
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
  end

  context 'In API' do
    context '在 namespace 和 route 中定义 scope' do
      let(:entity_class) do
        Class.new(Meta::Entity) do
          schema_name 'SomeEntity'

          property :foo, scope: '$foo'
          property :bar, scope: '$bar'
        end
      end

      it '继承了上方的 scopes' do
        the_entity_class = entity_class
        application = Class.new(Meta::Application) do
          meta do
            scope '$foo'
          end

          post '/request' do
            scope '$bar'
            params do
              param :nesting, required: true, ref: the_entity_class
            end
          end
        end

        doc = application.to_swagger_doc
        schema_name, schema_doc = doc[:components][:schemas].first
        expect(schema_name).to include('$foo')
        expect(schema_name).to include('$bar')
        expect(schema_doc[:properties].keys).to eq([:foo, :bar])
      end

      context '混合使用了 namespace 层的 scope 和 locked scope' do
        let(:entity_class) do
          Class.new(Meta::Entity) do
            schema_name 'Some'

            property :foo, scope: '$foo'
            property :bar, scope: '$bar'
          end
        end

        it '混合了二者的 scope' do
          the_entity_class = entity_class
          application = Class.new(Meta::Application) do
            meta do
              scope '$foo'
            end

            post '/request' do
              params do
                param :nesting, required: true, ref: the_entity_class.locked(scope: ['$bar'])
              end
            end
          end

          doc = application.to_swagger_doc
          schema_name, schema_doc = doc[:components][:schemas].first
          expect(schema_name).to include('$foo')
          expect(schema_name).to include('$bar')
          expect(schema_doc[:properties].keys).to eq([:foo, :bar])
        end

        context '实体中未定义任何 scope' do
          let(:entity_class) do
            Class.new(Meta::Entity) do
              schema_name 'Some'

              property :foo
              property :bar
            end
          end

          it '生成的实体名称不包含多余的 scope 名称' do
            the_entity_class = entity_class
            application = Class.new(Meta::Application) do
              meta do
                scope '$foo'
              end

              post '/request' do
                params do
                  param :nesting, required: true, ref: the_entity_class.locked(scope: ['$bar'])
                end
              end
            end

            doc = application.to_swagger_doc
            schema_name, schema_doc = doc[:components][:schemas].first
            expect(schema_name).not_to include('$foo')
            expect(schema_name).not_to include('$bar')
          end
        end
      end
    end
  end
end
