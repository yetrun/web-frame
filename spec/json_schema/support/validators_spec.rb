# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/entity'
require_relative '../../../lib/json_schema/schemas'

describe JsonSchema::ObjectValidators do
  describe '添加自定义验证' do
    before do
      JsonSchema::ObjectValidators[:validation_one] = proc {
        raise JsonSchema::ValidationErrors.new('x' => 'wrong one', 'y' => 'wrong one')
      }
      JsonSchema::ObjectValidators[:validation_two] = proc {
        raise JsonSchema::ValidationErrors.new('y' => 'wrong two', 'z' => 'wrong two')
      }
    end

    after do
      JsonSchema::ObjectValidators.delete(:validation_one)
      JsonSchema::ObjectValidators.delete(:validation_two)
    end

    it '检验 ObjectValidators' do
      builder = JsonSchema::ObjectSchemaBuilder.new do
        property :x
        property :y
        property :z

        validates :validation_one
        validates :validation_two
      end
      schema = builder.to_scope

      expect {
        schema.filter({ 'x' => -1, 'y' => -3, 'z' => -5 })
      }.to raise_error(JsonSchema::ValidationErrors) do |e|
        expect(e.errors).to eq(
          'x' => 'wrong one',
          'y' => 'wrong one',
          'z' => 'wrong two'
        )
      end
    end
  end
end

describe JsonSchema::BaseValidators do
  describe 'required' do
    it '不能为 nil' do
      expect {
        JsonSchema::BaseValidators[:required].call(nil, true)
      }.to raise_error(JsonSchema::ValidationError)
    end

    it 'String: 默认不允许空字符串' do
      expect {
        JsonSchema::BaseValidators[:required].call('', true, { type: 'string' })
      }.to raise_error(JsonSchema::ValidationError)
    end

    it 'String: 传递 `allow_empty: true` 后允许空字符串' do
      expect {
        JsonSchema::BaseValidators[:required].call('', { allow_empty: true }, { type: 'string' })
      }.not_to raise_error
    end

    it 'String: 传递 `allow_empty: false` 后不允许空字符串' do
      expect {
        JsonSchema::BaseValidators[:required].call('', { allow_empty: false }, { type: 'string' })
      }.to raise_error(JsonSchema::ValidationError)
    end

    it 'Array: 默认允许空数组' do
      expect {
        JsonSchema::BaseValidators[:required].call([], true, { type: 'array' })
      }.not_to raise_error
    end

    it 'Array: 传递 `allow_empty: true` 允许空数组' do
      expect {
        JsonSchema::BaseValidators[:required].call([], { allow_empty: true }, { type: 'array' })
      }.not_to raise_error
    end

    it 'Array: 传递 `allow_empty: false` 后不允许空数组' do
      expect {
        JsonSchema::BaseValidators[:required].call([], { allow_empty: false }, { type: 'array' })
      }.to raise_error(JsonSchema::ValidationError)
    end
  end
end
