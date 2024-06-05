# frozen_string_literal: true

require 'spec_helper'

# 完全重构 scope 的逻辑
describe 'JsonSchema::Scopes' do
  # 定义若干 Scope 常量
  before(:context) do
    module Test
      Scopes = Module.new
      Scopes::Foo = Class.new(Meta::Scope)
      Scopes::Bar = Class.new(Meta::Scope)
      Scopes::Admin = Class.new(Meta::Scope)
      Scopes::Detail = Class.new(Meta::Scope)
    end
  end

  context '定义一个简单实体' do
    let(:entity) do
      Class.new(Meta::Entity) do
        property :foo, scope: Test::Scopes::Foo
        property :bar, scope: Test::Scopes::Bar
      end
    end

    context '直接生成 schema' do
      let(:schema) do
        entity.to_schema
      end

      describe '基本行为' do
        it 'filter 时返回空字段' do
          value = schema.filter({ 'foo' => 'foo', 'bar' => 'bar' })
          expect(value.keys).to eq([])
        end

        it '文档生成时返回空字段' do
          doc = schema.to_schema_doc
          expect(doc[:properties]).to be_nil
        end
      end

      context '运行时提供单个 scope 选项' do
        it 'filter 时要求匹配' do
          value = schema.filter({ 'foo' => 'foo', 'bar' => 'bar' }, scope: Test::Scopes::Foo)
          expect(value.keys).to eq([:foo])
        end

        it '文档生成时要求匹配' do
          doc = schema.to_schema_doc(scope: Test::Scopes::Foo)
          expect(doc[:properties].keys).to eq([:foo])
        end
      end

      context '运行时提供多个 scope 选项' do
        it 'filter 时只要其中一个匹配' do
          value = schema.filter({ 'foo' => 'foo', 'bar' => 'bar' }, scope: [Test::Scopes::Foo, Test::Scopes::Bar])
          expect(value.keys).to eq([:foo, :bar])
        end

        it '文档生成时只要其中一个匹配' do
          doc = schema.to_schema_doc(scope: [Test::Scopes::Foo, Test::Scopes::Bar])
          expect(doc[:properties].keys).to eq([:foo, :bar])
        end
      end
    end

    context 'lock_scope' do
      let(:schema) do
        entity.lock_scope(Test::Scopes::Foo).to_schema
      end

      describe '就好像运行时传递了 scope 选项一样' do
        it 'filter 时自动匹配' do
          value = schema.filter({ 'foo' => 'foo', 'bar' => 'bar' })
          expect(value.keys).to eq([:foo])
        end

        it '文档生成时自动匹配' do
          doc = schema.to_schema_doc
          expect(doc[:properties].keys).to eq([:foo])
        end
      end

      context '运行时再提供 scope 选项' do
        it 'filter 时就好像提供了两个 scope 一样' do
          value = schema.filter({ 'foo' => 'foo', 'bar' => 'bar' }, scope: Test::Scopes::Bar)
          expect(value.keys).to eq([:foo, :bar])
        end

        it '文档生成时就好像提供了两个 scope 一样' do
          doc = schema.to_schema_doc(scope: Test::Scopes::Bar)
          expect(doc[:properties].keys).to eq([:foo, :bar])
        end
      end
    end
  end

  context 'scope 定义到深层字段' do
    let(:entity) do
      Class.new(Meta::Entity) do
        property :nesting do
          property :foo, scope: Test::Scopes::Foo
          property :bar, scope: Test::Scopes::Bar
        end
      end
    end

    context '直接生成 schema' do
      let(:schema) do
        entity.to_schema
      end

      describe '运行时 scope 可传递到深层' do
        it 'filter 时能够深层匹配' do
          value = { 'nesting' => { 'foo' => 'foo', 'bar' => 'bar' } }
          value = schema.filter(value, scope: Test::Scopes::Foo)
          expect(value[:nesting].keys).to eq([:foo])
        end

        it '文档生成时能够深层匹配' do
          doc = schema.to_schema_doc(scope: Test::Scopes::Foo)
          expect(doc[:properties][:nesting][:properties].keys).to eq([:foo])
        end
      end
    end

    context 'lock_scope' do
      let(:schema) do
        entity.lock_scope(Test::Scopes::Foo).to_schema
      end

      describe 'locked scope 能够传递到深层' do
        it 'filter 时能够深层匹配' do
          value = { 'nesting' => { 'foo' => 'foo', 'bar' => 'bar' } }
          value = schema.filter(value)
          expect(value[:nesting].keys).to eq([:foo])
        end

        it '文档生成时能够深层匹配' do
          doc = schema.to_schema_doc
          expect(doc[:properties][:nesting][:properties].keys).to eq([:foo])
        end
      end
    end
  end

  context 'with_common_options' do
    let(:user_entity) do
      Class.new(Meta::Entity) do
        scope Test::Scopes::Admin do
          property :age
          property :brief, scope: Test::Scopes::Detail
        end
      end
    end

    describe 'scope 匹配要求同时传递这两个 scope' do
      let(:schema) do
        user_entity.to_schema
      end

      context '仅传递顶层 scope 只能返回部分字段' do
        it 'filter 时能够部分匹配' do
          value = schema.filter({ 'age' => 18, 'brief' => 'brief' }, scope: Test::Scopes::Admin)
          expect(value.keys).to eq([:age])
        end

        it '文档生成时能够部分匹配' do
          doc = schema.to_schema_doc(scope: Test::Scopes::Admin)
          expect(doc[:properties].keys).to eq([:age])
        end
      end

      context '仅传递底层 scope 不能返回字段' do
        it 'filter 时不返回任何字段' do
          value = schema.filter({ 'age' => 18, 'brief' => 'brief' }, scope: Test::Scopes::Detail)
          expect(value.keys).to eq([])
        end

        it '文档生成时不返回任何字段' do
          doc = schema.to_schema_doc(scope: Test::Scopes::Detail)
          expect(doc[:properties]).to be_nil
        end
      end

      context '同时传递两个 scope 返回所有字段' do
        it 'filter 时返回所有字段' do
          value = schema.filter({ 'age' => 18, 'brief' => 'brief' }, scope: [Test::Scopes::Detail, Test::Scopes::Admin])
          expect(value.keys).to eq([:age, :brief])
        end

        it '文档生成时返回所有字段' do
          doc = schema.to_schema_doc(scope: [Test::Scopes::Detail, Test::Scopes::Admin])
          expect(doc[:properties].keys).to eq([:age, :brief])
        end
      end
    end
  end
end
