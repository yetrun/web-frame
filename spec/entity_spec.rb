require 'spec_helper'

describe Meta::Entity do
  describe 'scope' do
    let(:entity) do
      Class.new(Meta::Entity) do
        scope :foo do
          property :xxx
        end
      end
    end

    it '调用 filter 时传递 scope，返回值包含字段' do
      schema = entity.to_schema
      value = schema.filter({ 'xxx' => 1 }, scope: :foo)
      expect(value).to eq(xxx: 1)
    end

    it '调用 filter 时不传递 scope，返回值不包含字段' do
      schema = entity.to_schema
      value = schema.filter({ 'xxx' => 1 })
      expect(value).to eq({})
    end
  end

  describe 'merge' do
    let(:entity) do
      foo = Class.new(Meta::Entity) do
        property :foo
      end
      Class.new(Meta::Entity) do
        merge foo
      end
    end

    it '过滤 foo 属性' do
      schema = entity.to_schema
      value = schema.filter({ 'foo' => 1 })
      expect(value).to eq(foo: 1)
    end
  end
end