# frozen_string_literal: true

require 'spec_helper'

describe Meta::JsonSchema::TypeConverter do
  it '从 Integer 类型转化为 boolean' do
    # 测试 I18n 的错误消息
    expect {
      Meta::JsonSchema::TypeConverter.convert_value('34', 'boolean')
    }.to raise_error(Meta::JsonSchema::TypeConvertError)
  end
  it '从 Integer 类型转化为 number' do
    value = Meta::JsonSchema::TypeConverter.convert_value(34, 'number')
    expect(value).to eql(34)
  end

  it '从 Float 类型转化为 integer' do
    value = Meta::JsonSchema::TypeConverter.convert_value(34.0, 'integer')
    expect(value).to eql(34)
  end
end
