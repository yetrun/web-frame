# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/json_schema/schemas'

describe 'value' do
  it '使用 value' do
    schema = Dain::JsonSchema::BaseSchemaBuilder.build do
      property :foo, type: 'string', value: -> { 'foo' }
    end.to_schema
    expect {
      schema.filter(Object.new)
    }.not_to raise_error
  end
end
