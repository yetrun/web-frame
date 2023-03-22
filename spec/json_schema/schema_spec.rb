# frozen_string_literal: true

require 'spec_helper'

describe 'schema' do
  context 'discard_missing' do
    it '丢弃缺失的参数' do
      schema = Meta::JsonSchema::SchemaBuilderTool.build do
        param :foo, type: 'string'
        param :bar, type: 'string'
      end.to_schema

      filtered = schema.filter({ 'foo' => 'foo' }, discard_missing: true)
      expect(filtered).to eq(foo: 'foo')
    end
  end

  context '传递 nil 给数组参数' do
    shared_examples '过滤 nil 得到 nil' do
      specify do
        expect(schema.filter(nil)).to be nil
      end
    end

    context '定义标量数组' do
      let(:schema) do
        Meta::JsonSchema::SchemaBuilderTool.build type: 'array'
      end

      include_examples '过滤 nil 得到 nil'
    end

    context '定义对象数组' do
      let(:schema) do
        Meta::JsonSchema::SchemaBuilderTool.build type: 'array' do
          property :foo
          property :bar
        end
      end

      include_examples '过滤 nil 得到 nil'
    end
  end

  context 'render 数组和对象时，应用到非 JSON 类型的值' do
    # render 数组和对象时，应用到非 JSON 类型的值，它会把它们当作对应类型的值来看待。
    # 对于对象，obj[:foo] 会调用 obj.foo 方法；对于数组，arr[index]、arr.length 和
    # arr.each 都会对应地调用
    it 'render 对象时，调用对象的方法' do
      schema = Meta::JsonSchema::SchemaBuilderTool.build do
        property :foo
        property :bar
      end

      obj = Object.new
      def obj.foo; 'foo' end
      def obj.bar; 'bar' end

      expect(schema.filter(obj)).to eq(foo: 'foo', bar: 'bar')
    end

    it 'render 数组时，首先调用数组的 `to_a` 方法' do
      schema = Meta::JsonSchema::SchemaBuilderTool.build type: 'array'

      arr = Object.new
      def arr.to_a; [1, 2, 3] end

      expect(schema.filter(arr)).to eq([1, 2, 3])
    end
  end

  describe 'filter options' do
    describe '自定义验证器' do
      let (:schema) do
        Meta::JsonSchema::SchemaBuilderTool.build validate: ->(value) {
          raise Meta::JsonSchema::ValidationError, "value mustn't be zero"  if value == 0
        }
      end

      it '验证失败时抛出异常' do
        expect { schema.filter(0) }.to raise_error(Meta::JsonSchema::ValidationError)
      end
    end

    describe 'using Entity' do
      context '使用单独的一个 Entity' do
        it '成功使用外部 Entity 类' do
          entity_class = Class.new(Meta::Entity) do
            property :a
            property :b
          end

          schema = Meta::JsonSchema::SchemaBuilderTool.build do
            property :foo, required: true, using: entity_class
          end

          obj = Object.new
          def obj.a; 'a' end
          def obj.b; 'b' end

          expect { schema.filter('foo' => obj) }.not_to raise_error
        end
      end
    end

    describe 'render: false' do
      it '不过滤 render 选项为 false 的属性' do
        schema = Meta::JsonSchema::SchemaBuilderTool.build do
          property :foo
          property :bar, render: false
        end

        value = schema.filter({ 'foo' => 'foo', 'bar' => 'bar' }, stage: :render)
        expect(value.keys).to eq([:foo])
      end
    end
  end

  describe 'default: 默认值' do
    it '生成 boolean 类型的默认值' do
      schema = Meta::JsonSchema::SchemaBuilderTool.build do
        property :flag, type: 'boolean', default: false
      end

      value = schema.filter({})
      expect(value).to eq({ flag: false })
    end
  end

  describe 'format validator' do
    it 'nil 值不会触发 format validator' do
      schema = Meta::JsonSchema::SchemaBuilderTool.build do
        property :number, type: 'string', format: /\d+/
      end

      expect {
        schema.filter(number: nil)
      }.not_to raise_error
    end
  end

  describe 'ref' do
    it '使用 ref: Entity' do
      entity = Class.new(Meta::Entity) do
        property :a
        property :b
      end
      schema = Meta::JsonSchema::SchemaBuilderTool.build ref: entity.to_schema

      value = schema.filter({ 'a' => 'a', 'b' => 'b', 'c' => 'c' })
      expect(value).to eq({ a: 'a', b: 'b' })
    end

    it '数组' do
      the_entity = Class.new(Meta::Entity) do
        param :name
        param :age
      end
      schema = Meta::JsonSchema::SchemaBuilderTool.build type: 'array', ref: the_entity
      value = [{ name: 'Jim', age: 18 }]
      expect(schema.filter(JSON.parse(JSON.generate(value)))).to eq(value)
    end
  end

  describe 'dynamic_ref' do
    it '使用 dynamic_ref.resolve' do
      entity_a = Class.new(Meta::Entity) do
        property :a
      end
      entity_b = Class.new(Meta::Entity) do
        property :b
      end
      schema = Meta::JsonSchema::SchemaBuilderTool.build dynamic_ref: {
        resolve: ->(value) {
          value['name'] === 'a' ? entity_a : entity_b
        }
      }

      value = schema.filter({ 'name' => 'a', 'a' => 'a', 'b' => 'b' })
      expect(value).to eq(a: 'a')
    end

    it '使用多态时 `required` 选项应起作用' do
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

    it '使用多态时 `scope` 选项应起作用' do
      inner_entity = Class.new(Meta::Entity) do
        property :a
      end
      schema = Meta::JsonSchema::SchemaBuilderTool.build do
        property :foo, scope: :foo, dynamic_ref: { resolve: ->(value) { inner_entity } }
        property :bar, scope: :bar, dynamic_ref: { resolve: ->(value) { inner_entity } }
      end

      value = schema.filter({
        'foo' => { 'a' => 'a', 'b' => 'b'  },
        'bar' => { 'a' => 'a', 'b' => 'b' }
      }, scope: [:bar])
      expect(value).not_to be_key(:foo)
      expect(value).to be_key(:bar)
    end

    context 'using Proc' do
      it '等效于 using: { resolve }' do
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

      context '放在 render 下也能生效' do
        it '等效于 using: { resolve }' do
          entity_a = Class.new(Meta::Entity) do
            property :a
          end
          entity_b = Class.new(Meta::Entity) do
            property :b
          end
          schema = Meta::JsonSchema::SchemaBuilderTool.build do
            property :foo, render: {
              required: true,
              dynamic_ref: ->(value) {
                value['name'] === 'a' ? entity_a : entity_b
              }
            }
          end

          value = schema.filter({ 'foo' => { 'name' => 'a', 'a' => 'a', 'b' => 'b' } }, stage: :render)
          expect(value[:foo]).to eq(a: 'a')
        end
      end

      context 'dynamic_using' do
        it '它是 dynamic_ref 的别名' do
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
  end
end
