# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/json_schema/support/type_converter'

describe JsonSchema::TypeConverter do
  it '从 integer 类型转化为 float' do
    value = JsonSchema::TypeConverter.convert_value(34, 'float')
    expect(value).to eql(34.0)
  end

  it '从 float 类型转化为 integer' do
    value = JsonSchema::TypeConverter.convert_value(34.0, 'integer')
    expect(value).to eql(34)
  end
end
