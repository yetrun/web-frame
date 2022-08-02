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
end
