# frozen_string_literal: true

require 'spec_helper'

describe '只测试与当初 Scope 有关的测试' do
  describe 'Meta::Scope' do
    # it '调用 new 方法应当抛出异常' do
    #   expect { Meta::Scope.new }.to raise_error(NoMethodError)
    # end

    it '创建 Scope 就是继承 Meta::Scope 类' do
      scope = Class.new(Meta::Scope)
      expect(scope).to be_match(scope)
      expect(scope).to be_match([scope])
    end

    it '对于匿名类 scope 名称时应当抛出异常' do
      scope = Class.new(Meta::Scope)
      expect { scope.scope_name }.to raise_error(Meta::Scope::Errors::NameNotSet)
    end

    it 'Meta::Scope 子类设置常量以后获取 scope 名称' do
      Foo = Class.new(Meta::Scope)
      expect(Foo.scope_name).to eq('Foo')
    end

    it '设置 scope 名称' do
      scope = Class.new(Meta::Scope)
      scope.scope_name = 'bar'
      expect(scope.scope_name).to eq('bar')
    end
  end

  describe 'Meta::Scope.and' do
    shared_examples '测试 And' do |and_method|
      it '测试 And' do
        scope_one = Class.new(Meta::Scope)
        scope_two = Class.new(Meta::Scope)
        scope_three = Class.new(Meta::Scope)
        and_scope = and_method.call(scope_one, scope_two)

        expect(and_scope).to be_match([scope_two, scope_three, scope_one])
        expect(and_scope).not_to be_match([scope_one, scope_three])
        expect(and_scope).not_to be_match([scope_three, scope_two])
      end
    end

    include_examples '测试 And', ->(scope_one, scope_two) { scope_one.and(scope_two) }
    include_examples '测试 And', ->(scope_one, scope_two) { scope_one & scope_two }
    include_examples '测试 And', ->(scope_one, scope_two) { Meta::Scope.and(scope_one, scope_two) }

    it 'And 可以设置名称' do
      scope_one = Class.new(Meta::Scope)
      scope_two = Class.new(Meta::Scope)
      and_scope = scope_one.and(scope_two)
      and_scope.scope_name = 'and_scope'

      expect(and_scope.scope_name).to eq('and_scope')
    end
  end

  describe 'Meta::Scope.or' do
    shared_examples '测试 Or' do |or_method|
      it '测试 Or' do
        scope_one = Class.new(Meta::Scope)
        scope_two = Class.new(Meta::Scope)
        scope_three = Class.new(Meta::Scope)
        or_scope = or_method.call(scope_one, scope_two)

        expect(or_scope).to be_match([scope_two, scope_three, scope_one])
        expect(or_scope).to be_match([scope_one, scope_three])
        expect(or_scope).to be_match([scope_three, scope_two])
        expect(or_scope).not_to be_match([scope_three])
      end
    end

    include_examples '测试 Or', ->(scope_one, scope_two) { scope_one.or(scope_two) }
    include_examples '测试 Or', ->(scope_one, scope_two) { scope_one | scope_two }
    include_examples '测试 Or', ->(scope_one, scope_two) { Meta::Scope.or(scope_one, scope_two) }
  end

  describe 'Meta::Scope.include_scope' do
    it '继承若干个 Scope' do
      scope_one = Class.new(Meta::Scope)
      scope_two = Class.new(Meta::Scope)
      scope_two.include_scope(scope_one)

      expect(scope_two).to be_match(scope_one)
    end

    it '使用继承原语' do
      scope_one = Class.new(Meta::Scope)
      scope_two = Class.new(scope_one)

      expect(scope_two).to be_match(scope_one)
    end

    it '使用 include 原语' do
      scope_one = Class.new(Meta::Scope)
      scope_two = Class.new(Meta::Scope)
      scope_two.include(scope_one)

      expect(scope_two).to be_match(scope_one)
    end
  end
end
