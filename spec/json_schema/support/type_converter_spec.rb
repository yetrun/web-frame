# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/json_schema/support/type_converter'

describe Dain::JsonSchema::TypeConverter do
  it '从 Integer 类型转化为 number' do
    value = Dain::JsonSchema::TypeConverter.convert_value(34, 'number')
    expect(value).to eql(34)
  end

  it '从 Float 类型转化为 integer' do
    value = Dain::JsonSchema::TypeConverter.convert_value(34.0, 'integer')
    expect(value).to eql(34)
  end
end
