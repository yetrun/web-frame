# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/json_schema/schemas'

describe Dain::JsonSchema::Validators do
  describe 'required' do
    it '不能为 nil' do
      expect {
        Dain::JsonSchema::Validators[:required].call(nil, true)
      }.to raise_error(Dain::JsonSchema::ValidationError)
    end

    it 'String: 默认不允许空字符串' do
      expect {
        Dain::JsonSchema::Validators[:required].call('', true, { type: 'string' })
      }.to raise_error(Dain::JsonSchema::ValidationError)
    end

    it 'String: 传递 `allow_empty: true` 后允许空字符串' do
      expect {
        Dain::JsonSchema::Validators[:required].call('', { allow_empty: true }, { type: 'string' })
      }.not_to raise_error
    end

    it 'String: 传递 `allow_empty: false` 后不允许空字符串' do
      expect {
        Dain::JsonSchema::Validators[:required].call('', { allow_empty: false }, { type: 'string' })
      }.to raise_error(Dain::JsonSchema::ValidationError)
    end

    it 'Array: 默认允许空数组' do
      expect {
        Dain::JsonSchema::Validators[:required].call([], true, { type: 'array' })
      }.not_to raise_error
    end

    it 'Array: 传递 `allow_empty: true` 允许空数组' do
      expect {
        Dain::JsonSchema::Validators[:required].call([], { allow_empty: true }, { type: 'array' })
      }.not_to raise_error
    end

    it 'Array: 传递 `allow_empty: false` 后不允许空数组' do
      expect {
        Dain::JsonSchema::Validators[:required].call([], { allow_empty: false }, { type: 'array' })
      }.to raise_error(Dain::JsonSchema::ValidationError)
    end
  end
end
