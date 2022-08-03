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

  context '传递 nil 给数组参' do
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
end
