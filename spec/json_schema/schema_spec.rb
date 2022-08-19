# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/json_schema/schemas'

describe 'schema' do
  context 'discard_missing' do
    it '丢弃缺失的参数' do
      schema = Dain::JsonSchema::BaseSchemaBuilder.build do
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
        Dain::JsonSchema::BaseSchemaBuilder.build type: 'array'
      end

      include_examples '过滤 nil 得到 nil'
    end

    context '定义对象数组' do
      let(:schema) do
        Dain::JsonSchema::BaseSchemaBuilder.build type: 'array' do
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
      schema = Dain::JsonSchema::BaseSchemaBuilder.build do
        property :foo
        property :bar
      end

      obj = Object.new
      def obj.foo; 'foo' end
      def obj.bar; 'bar' end

      expect(schema.filter(obj)).to eq(foo: 'foo', bar: 'bar')
    end

    it 'render 数组时，首先调用数组的 `to_a` 方法' do
      schema = Dain::JsonSchema::BaseSchemaBuilder.build type: 'array'

      arr = Object.new
      def arr.to_a; [1, 2, 3] end

      expect(schema.filter(arr)).to eq([1, 2, 3])
    end
  end
end
