# frozen_string_literal: true

require 'spec_helper'

describe 'value' do
  it '调用 `value` 时父级对象不存在对应键值不会抛出异常' do
    schema = Meta::JsonSchema::SchemaBuilderTool.build do
      property :foo, type: 'string', value: lambda { 'foo' }
    end.to_schema

    expect {
      schema.filter(Object.new)
    }.not_to raise_error
  end

  it '调用 `value` 时块接受父级传值' do
    schema = Meta::JsonSchema::SchemaBuilderTool.build do
      property :foo, type: 'string', value: lambda { |parent| parent['bar'] }
    end.to_schema

    expect(
      schema.filter('bar' => 'foo' )
    ).to eq({ foo: 'foo' })
  end

  it '调用 `value` 时可在指定的环境下执行' do
    schema = Meta::JsonSchema::SchemaBuilderTool.build do
      property :foo, type: 'string', value: lambda { resolve_foo }
    end.to_schema

    object = Object.new
    def object.resolve_foo; 'foo' end

    expect(
      schema.filter(object, execution: object)
    ).to eq({ foo: 'foo' })
  end

  it '对于根级别的定义，调用 `value` 时块也能正常执行' do
    schema = Meta::JsonSchema::SchemaBuilderTool.build type: 'string', value: lambda { 'foo' }

    expect(
      schema.filter('bar')
    ).to eq('foo')
  end
end
