# frozen_string_literal: true

require 'spec_helper'

describe 'schema' do
  # 这个测试合集主要测试 schema 的 filter 方法。
  # 有关 SchemaBuilder 的构建选项，如 value:, default: 等，参见 schema_builder_spec.rb
  describe '.filter' do
    describe '传递特殊的 value' do
      context 'value is nil' do
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

      context 'value is not a Hash' do
        let(:value) {
          obj = Object.new
          def obj.a; 'a' end
          def obj.b; 'b' end
          obj
        }

        it '调用对象的方法获取值' do
          schema = Meta::JsonSchema::SchemaBuilderTool.build do
            property :a
            property :b
          end
          expect(schema.filter(value)).to eq(a: 'a', b: 'b')
        end
      end

      context 'value is not an array' do
        let(:value) do
          arr = Object.new
          def arr.to_a; [1, 2, 3] end
          arr
        end

        it '调用 to_a 获取数组元素' do
          schema = Meta::JsonSchema::SchemaBuilderTool.build type: 'array'
          expect(schema.filter(value)).to eq([1, 2, 3])
        end
      end
    end

    describe '传递运行时选项' do
      describe 'stage:' do
        context '在对象内部元素设置 render: false' do
          it '过滤掉 render: false 的属性' do
            schema = Meta::JsonSchema::SchemaBuilderTool.build do
              property :a
              property :b, param: false
              property :c, render: false
            end

            value = schema.filter({ 'a' => 'a', 'b' => 'b', 'c' => 'c' }, stage: :render)
            expect(value.keys).to eq([:a, :b])
          end
        end
      end

      describe 'discard_missing:' do
        context 'is true' do
          it '丢弃缺失的字段' do
            schema = Meta::JsonSchema::SchemaBuilderTool.build do
              param :foo, type: 'string'
              param :bar, type: 'string'
            end.to_schema

            filtered = schema.filter({ 'foo' => 'foo' }, discard_missing: true)
            expect(filtered).to eq(foo: 'foo')
          end
        end

        context 'is false' do
          it '保留缺失的字段' do
            schema = Meta::JsonSchema::SchemaBuilderTool.build do
              param :foo, type: 'string'
              param :bar, type: 'string'
            end.to_schema

            filtered = schema.filter({ 'foo' => 'foo' }, discard_missing: false)
            expect(filtered).to eq(foo: 'foo', bar: nil)
          end
        end
      end

      describe 'extra_properties:' do
        context 'set to "raise_error"' do
          it '抛出异常' do
            schema = Meta::JsonSchema::SchemaBuilderTool.build do
              param :foo, type: 'string'
            end.to_schema

            expect {
              schema.filter({ 'foo' => 'foo', 'bar' => 'bar' }, extra_properties: :raise_error)
            }.to raise_error(Meta::JsonSchema::ValidationError)
          end
        end
      end

      describe 'user_data:' do
        it '传递用户数据' do
          schema = Meta::JsonSchema::SchemaBuilderTool.build do
            property :foo, value: Proc.new { |parent, user_data| parent['foo'] + user_data[:bar] }
          end.to_schema

          filtered = schema.filter({ 'foo' => 'foo' }, user_data: { bar: 'bar' })
          expect(filtered).to eq(foo: 'foobar')
        end

        it '在嵌套多层下，传递用户数据' do
          schema = Meta::JsonSchema::SchemaBuilderTool.build do
            property :nested do
              property :foo, value: Proc.new { |parent, user_data| parent['foo'] + user_data[:bar] }
            end
          end.to_schema

          filtered = schema.filter({ 'nested' => { 'foo' => 'foo' } }, user_data: { bar: 'bar' })
          expect(filtered[:nested]).to eq(foo: 'foobar')
        end
      end
    end
  end
end
