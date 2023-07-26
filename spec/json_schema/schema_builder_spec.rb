
# frozen_string_literal: true

require 'spec_helper'

describe 'Schema Builders' do
  describe 'build array schema' do
    it '属于数组的属性要保留' do
      array_schema = Meta::JsonSchema::SchemaBuilderTool.build type: 'array', using: Class.new(Meta::Entity), value: proc { |board| [] }
      expect(array_schema.options[:value]).to be_a(Proc)
    end

    it '同时使用 ref 和 items 不会报错' do
      expect {
        Meta::JsonSchema::SchemaBuilderTool.build \
          type: 'array',
          ref: Class.new(Meta::Entity),
          items: { type: 'object' }
      }.not_to raise_error
    end
  end

  describe 'ObjectSchemaBuilder' do
    describe '#locked' do
      describe 'lock scope' do
        let(:builder) do
          Meta::JsonSchema::ObjectSchemaBuilder.new do
            property :xxx, scope: 'xxx'
            property :yyy, scope: 'yyy'
            property :zzz
          end
        end
        let(:normal_schema) { builder.to_schema }
        let(:scoped_schema) { builder.lock_scope('xxx').to_schema }
        let(:input_value) { { 'xxx' => 'xxx', 'yyy' => 'yyy', 'zzz' => 'zzz' } }

        it '当不传递 scope 时，调用 filter 相当于传递了锁住的 scope' do
          expect(
            scoped_schema.filter(input_value)
          ).to eq(
            normal_schema.filter(input_value, scope: 'xxx')
          )
        end

        it '传递了其他的 scope，调用 filter 相当于传递了锁住的 scope 加上传递的 scope' do
          expect(
            scoped_schema.filter(input_value, scope: 'yyy')
          ).to eq(
            normal_schema.filter(input_value, scope: ['xxx', 'yyy'])
          )
        end

        context '定义更深层次' do
          let(:builder) {
            Meta::JsonSchema::ObjectSchemaBuilder.new do
              property :xxx, scope: 'xxx'
              property :yyy, scope: 'yyy'
              property :zzz do
                property :xx, scope: 'xxx'
                property :yy, scope: 'yyy'
              end
            end
          }
          let(:input_value) { { 'xxx' => 'xxx', 'yyy' => 'yyy', 'zzz' => { 'xx' => 'xx', 'yy' => 'yy' } } }

          it '对内部模块仍然有用' do
            expect(
              scoped_schema.filter(input_value)
            ).to eq(
              normal_schema.filter(input_value, scope: 'xxx')
            )
          end
        end
      end

      describe 'lock exclude' do
        let(:builder) do
          Meta::JsonSchema::ObjectSchemaBuilder.new do
            property :xxx
            property :yyy
          end
        end
        let(:normal_schema) { builder.to_schema }
        let(:excluded_schema) { builder.lock_exclude([:yyy]).to_schema }
        let(:input_value) { { 'xxx' => 'xxx', 'yyy' => 'yyy' } }

        it '当不传递 exclude 时，相当于传递了锁住的 exclude' do
          expect(
            excluded_schema.filter(input_value)
          ).to eq(
            normal_schema.filter(input_value, exclude: [:yyy])
          )
        end

        it '当传递了 exclude 时，仍相当于传递了锁住的 exclude' do
          expect(
            excluded_schema.filter(input_value, exclude: [:xxx])
          ).to eq(
            normal_schema.filter(input_value, exclude: [:yyy])
          )
        end
      end

      describe '连续 lock' do
        let(:builder) do
          Meta::JsonSchema::ObjectSchemaBuilder.new do
            property :xxx, scope: 'xxx'
            property :yyy, scope: 'yyy'
            property :zzz
          end.locked(scope: 'xxx').locked(scope: 'yyy')
        end

        it '合并 lock 的效果' do
          schema = builder.to_schema
          expect(
            schema.filter({ 'xxx' => 'xxx', 'yyy' => 'yyy', 'zzz' => 'zzz' })
          ).to eq(
            { xxx: 'xxx', yyy: 'yyy', zzz: 'zzz' }
          )
        end
      end
    end

    describe 'option if:' do
      it 'Object 内的属性可配置一个 if 动态地决定是否渲染该属性' do
        schema = Meta::JsonSchema::SchemaBuilderTool.build do
          property :foo, if: ->{ self == 'foo' }
          property :bar, if: ->{ self == 'bar' }
        end

        value = schema.filter({ 'foo' => 'foo', 'bar' => 'bar' }, execution: 'foo')
        expect(value).to eq({ foo: 'foo' })
      end
    end
  end

  describe 'options' do
    describe 'default:' do
      it 'boolean 类型的默认值设置工作正常' do
        schema = Meta::JsonSchema::SchemaBuilderTool.build type: 'boolean', default: false

        value = schema.filter(nil)
        expect(value.class).to be(FalseClass)
      end

      it '使用引用对象时一般不会发生干扰' do
        schema = Meta::JsonSchema::SchemaBuilderTool.build default: []

        schema.filter(nil) << 'foo'
        array = schema.filter(nil)
        expect(array).to be_empty
      end

      it '支持使用块' do
        schema = Meta::JsonSchema::SchemaBuilderTool.build default: ->{ [] }
        array = schema.filter(nil)
        expect(array).to eq []
      end
    end

    describe 'before:' do
      it '前置解析值' do
        schema = Meta::JsonSchema::SchemaBuilderTool.build before: ->(value) { 'foo' }

        value = schema.filter(nil)
        expect(value).to eq('foo')
      end
    end

    describe 'value:' do
      it '调用 `value` 时父级对象不存在对应键值不会抛出异常' do
        schema = Meta::JsonSchema::SchemaBuilderTool.build do
          property :foo, type: 'string', value: lambda { 'foo' }
        end

        expect {
          schema.filter(Object.new)
        }.not_to raise_error
      end

      it '调用 `value` 时块接受父级传值' do
        schema = Meta::JsonSchema::SchemaBuilderTool.build do
          property :foo, type: 'string', value: lambda { |parent| parent['bar'] }
        end

        expect(
          schema.filter('bar' => 'foo' )
        ).to eq({ foo: 'foo' })
      end

      it '调用 `value` 时可在指定的环境下执行' do
        schema = Meta::JsonSchema::SchemaBuilderTool.build do
          property :foo, type: 'string', value: lambda { resolve_foo }
        end

        object = Object.new
        def object.resolve_foo; 'foo' end

        expect(
          schema.filter(object, execution: object)
        ).to eq({ foo: 'foo' })
      end

      it '对于根级别的定义，调用 `value` 时块也能正常执行' do
        schema = Meta::JsonSchema::SchemaBuilderTool.build type: 'string', value: lambda { 'foo' }

        expect(
          schema.filter('bar')
        ).to eq('foo')
      end
    end

    describe 'validators' do
      describe 'format:' do
        it 'nil 值不会触发 format validator' do
          schema = Meta::JsonSchema::SchemaBuilderTool.build do
            property :number, type: 'string', format: /\d+/
          end

          expect {
            schema.filter(number: nil)
          }.not_to raise_error
        end
      end

      describe 'validate:' do
        let(:schema) do
          Meta::JsonSchema::SchemaBuilderTool.build validate: ->(value) {
            raise Meta::JsonSchema::ValidationError, "value mustn't be zero"  if value == 0
          }
        end

        it '作为自定义验证器' do
          expect { schema.filter(0) }.to raise_error(Meta::JsonSchema::ValidationError)
        end
      end
    end

    describe 'ref:' do
      let(:entity) do
        Class.new(Meta::Entity) do
          property :a
          property :b
        end
      end

      it '属性的过滤进一步交给 ref 的实体处理' do
        schema = Meta::JsonSchema::SchemaBuilderTool.build ref: entity
        value = schema.filter({ 'a' => 'a', 'b' => 'b', 'c' => 'c' })
        expect(value).to eq({ a: 'a', b: 'b' })
      end

      it '属性的过滤进一步交给 ref 的实体处理（数组）' do
        schema = Meta::JsonSchema::SchemaBuilderTool.build type: 'array', ref: entity
        value = schema.filter([{ 'a' => 'a', 'b' => 'b', 'c' => 'c' }])
        expect(value).to eq([{ a: 'a', b: 'b' }])
      end
    end

    describe 'dynamic_ref:' do
      describe 'dynamic_ref.resolve:' do
        it '动态获得实体' do
          entity_a = Class.new(Meta::Entity) do
            property :a
          end
          entity_b = Class.new(Meta::Entity) do
            property :b
          end
          schema = Meta::JsonSchema::SchemaBuilderTool.build dynamic_ref: {
            resolve: ->(object_value) {
              object_value['name'] === 'a' ? entity_a : entity_b
            }
          }

          value = schema.filter({ 'name' => 'a', 'a' => 'a', 'b' => 'b' })
          expect(value).to eq(a: 'a')
        end

        context '同时设置其他选项' do
          it '同时设置 `required: true` 时正常' do
            inner_entity = Class.new(Meta::Entity) do
              property :a
            end
            schema = Meta::JsonSchema::SchemaBuilderTool.build do
              property :foo, required: true, dynamic_ref: { resolve: ->(value) { inner_entity } }
            end

            expect {
              schema.filter({})
            }.to raise_error(Meta::JsonSchema::ValidationErrors)
          end

          it '同时设置 `scope` 时正常' do
            inner_entity = Class.new(Meta::Entity) do
              property :a
            end
            schema = Meta::JsonSchema::SchemaBuilderTool.build do
              property :foo, scope: 'foo', dynamic_ref: { resolve: ->(value) { inner_entity } }
              property :bar, scope: 'bar', dynamic_ref: { resolve: ->(value) { inner_entity } }
            end

            value = schema.filter({
              'foo' => { 'a' => 'a', 'b' => 'b'  },
              'bar' => { 'a' => 'a', 'b' => 'b' }
            }, scope: 'bar')
            expect(value).not_to be_key(:foo)
            expect(value).to be_key(:bar)
          end
        end

        context '放在 render 下' do
          it '亦正常' do
            entity_a = Class.new(Meta::Entity) do
              property :a
            end
            entity_b = Class.new(Meta::Entity) do
              property :b
            end
            schema = Meta::JsonSchema::SchemaBuilderTool.build do
              property :foo, render: {
                required: true,
                dynamic_ref: { resolve: ->(value) {
                  value['name'] === 'a' ? entity_a : entity_b
                } }
              }
            end

            value = schema.filter({ 'foo' => { 'name' => 'a', 'a' => 'a', 'b' => 'b' } }, stage: :render)
            expect(value[:foo]).to eq(a: 'a')
          end
        end
      end

      describe 'dynamic_ref: Proc' do
        it '等效于 dynamic_ref: { resolve: Proc }' do
          entity_a = Class.new(Meta::Entity) do
            property :a
          end
          entity_b = Class.new(Meta::Entity) do
            property :b
          end
          schema = Meta::JsonSchema::SchemaBuilderTool.build do
            property :foo, required: true, dynamic_ref: ->(value) {
              value['name'] === 'a' ? entity_a : entity_b
            }
          end

          value = schema.filter('foo' => { 'name' => 'a', 'a' => 'a', 'b' => 'b' })
          expect(value[:foo]).to eq(a: 'a')
        end
      end

      describe 'dynamic_using' do
        it '是 dynamic_ref 的别名' do
          entity_a = Class.new(Meta::Entity) do
            property :a
          end
          entity_b = Class.new(Meta::Entity) do
            property :b
          end
          schema = Meta::JsonSchema::SchemaBuilderTool.build do
            property :foo, required: true, dynamic_using: ->(value) {
              value['name'] === 'a' ? entity_a : entity_b
            }
          end

          value = schema.filter('foo' => { 'name' => 'a', 'a' => 'a', 'b' => 'b' })
          expect(value[:foo]).to eq(a: 'a')
        end
      end
    end

    describe 'param' do
      it '可以设置 param 为 true' do
        expect {
          Meta::JsonSchema::SchemaBuilderTool.build do
            property :foo, param: true
          end
        }.not_to raise_error
      end
    end
  end
end
