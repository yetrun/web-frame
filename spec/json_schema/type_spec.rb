# frozen_string_literal: true

require 'spec_helper'

describe 'JsonSchema 类型' do
  describe '字符串类型' do
    it '可以定义字符串类型的 schema' do
      schema = Meta::JsonSchema::SchemaBuilderTool.build type: 'integer'
      expect(schema.filter('34')).to eq 34
    end
  end

  describe '自定义类型' do
    # 自定义 Address 类型
    let(:address_class) do
      Class.new do
        attr_accessor :city, :street

        def initialize(options = {})
          @city = options['city']
          @street = options['street']
        end
      end
    end

    context '在 ObjectSchema 内部的 property 上定义' do
      let(:address_class) do
        Class.new do
          attr_accessor :city, :street

          def initialize(options = {})
            @city = options['city']
            @street = options['street']
          end
        end
      end

      let(:schema) do
        address_class = self.address_class
        Class.new(Meta::Entity) do
          property :address, type: address_class do
            property :city
            property :street
          end
        end.to_schema
      end

      it '生成的文档中 schema 类型是 object' do
        doc = schema.to_schema_doc(stage: :param)
        expect(doc[:properties][:address][:type]).to eq 'object'
      end

      it '参数过滤后值的类型是 address_class' do
        value = { 'address' => { 'city' => 'city', 'street' => 'street' } }
        expect(schema.filter(value, stage: :param)[:address]).to be_a address_class
      end

      it '渲染时提前检查参数类型是不是 address_class' do
        expect {
          schema.filter({ address: address_class.new }, stage: :render)
        }.not_to raise_error

        expect {
          schema.filter({ address: {} }, stage: :render)
        }.to raise_error(Meta::JsonSchema::ValidationErrors)
      end
    end

    context '直接用 SchemaBuilderTool.build 定义' do
      let(:schema) do
        address_class = self.address_class
        Meta::JsonSchema::SchemaBuilderTool.build type: address_class do
          property :city
          property :street
        end
      end

      it '生成的文档中 schema 类型是 object' do
        schema = self.schema
        doc = schema.to_schema_doc(stage: :param)
        expect(doc[:type]).to eq 'object'
      end

      it '参数过滤后值的类型是 address_class' do
        value = { 'city' => 'city', 'street' => 'street' }
        expect(schema.filter(value, stage: :param)).to be_a address_class
      end

      it '渲染时提前检查参数类型是不是 address_class' do
        expect {
          schema.filter(address_class.new, stage: :render)
        }.not_to raise_error

        expect {
          schema.filter({}, stage: :render)
        }.to raise_error(Meta::JsonSchema::ValidationErrors)
      end
    end
  end
end
