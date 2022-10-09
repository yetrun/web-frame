
# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/json_schema/schemas'
require_relative '../../lib/entity'

describe 'Schema Builders' do
  it '属于数组的属性要保留' do
    schema = Dain::JsonSchema::BaseSchemaBuilder.build do
      property :array_value, type: 'array', using: Class.new(Dain::Entities::Entity), value: proc { |board| [] }
    end.to_schema

    array_schema = schema.properties[:array_value]
    expect(array_schema.items.is_a?(Dain::JsonSchema::ObjectSchema)).to be true
    expect(array_schema.render_options.include?(:value)).to be true
  end

  # TODO: 组织测试结构
  it '使用 scope 约束 Schema' do
    builder = Dain::JsonSchema::ObjectSchemaBuilder.new do
      property :xxx, scope: 'xxx'
      property :yyy, scope: 'yyy'
      property :zzz
    end

    # TODO: 是不是应该限制为仅 Dain::Entities::Entity 拥有
    schema = builder.lock_scope('xxx').to_schema

    value = schema.filter({})
    expect(value.keys).to eq([:xxx, :zzz]) # 相当于自动传递 scope: 'xxx'

    value = schema.filter({}, scope: 'yyy')
    expect(value.keys).to eq([:xxx, :zzz]) # 忽略用户传递的 scope 选项
  end

  it '使用 scope 约束 Schema：内部模块依然有用' do
    builder = Dain::JsonSchema::ObjectSchemaBuilder.new do
      property :xxx, scope: 'xxx'
      property :yyy, scope: 'yyy'
      property :zzz do
        property :xx, scope: 'xxx'
        property :yy, scope: 'yyy'
      end
    end

    # TODO: 是不是应该限制为仅 Dain::Entities::Entity 拥有
    schema = builder.lock_scope('xxx').to_schema

    value = schema.filter({ 'zzz' => {} })
    expect(value).to eq({
      xxx: nil,
      zzz: {
        xx: nil
      }
    }) # 相当于自动传递 scope: 'xxx'
  end

  it '使用 exclude 约束 Schema' do
    builder = Dain::JsonSchema::ObjectSchemaBuilder.new do
      property :xxx
      property :yyy
    end

    schema = builder.lock_exclude([:yyy]).to_schema

    value = schema.filter({})
    expect(value.keys).to eq([:xxx])
  end
end
