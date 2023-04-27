require 'spec_helper'
require_relative '../../lib/meta/route_dsl/around_action_builder'

describe 'RouteDSL::AroundActionBuilder' do
  let(:execution) do
    obj = Object.new
    obj.instance_exec { @holder = [] }
    def obj.holder; @holder; end
    obj
  end

  it '#build: 测试 around 的效果' do
    action_builder = Meta::RouteDSL::AroundActionBuilder.new
    action_builder.around do |next_action|
      @holder << 1
      next_action.execute(self)
      @holder << 5
    end
    action_builder.around do |next_action|
      @holder << 2
      next_action.execute(self)
      @holder << 4
    end
    action_builder.around do
      @holder << 3
    end
    action = action_builder.build
    action.execute(execution)

    expect(execution.holder).to eq([1, 2, 3, 4, 5])
  end

  it '#build: 测试 around 的效果（结合 before 和 after）' do
    action_builder = Meta::RouteDSL::AroundActionBuilder.new
    action_builder.around do |next_action|
      @holder << 1
      next_action.execute(self)
      @holder << 5
    end
    action_builder.before do
      @holder << 2
    end
    action_builder.after do
      @holder << 3
    end
    action_builder.after do
      @holder << 4
    end

    action = action_builder.build
    action.execute(execution)
    expect(execution.holder).to eq([1, 2, 3, 4, 5])
  end

  it '.build: 综合测试 before、after、around 的效果' do
    b1 = Proc.new { @holder << 1 }
    b2 = Proc.new { @holder << 2 }
    r1 = Proc.new do |next_action|
      @holder << 3
      next_action.execute(self)
      @holder << 7
    end
    r2 = Proc.new do |next_action|
      @holder << 4
      next_action.execute(self)
      @holder << 6
    end
    a = Proc.new { @holder << 5 }
    e1 = Proc.new { @holder << 8 }
    e2 = Proc.new { @holder << 9 }

    action = Meta::RouteDSL::AroundActionBuilder.build(
      before: [b1, b2],
      after: [e1, e2],
      around: [r1, r2],
      action: a
    )
    action.execute(execution)

    expect(execution.holder).to eq([1, 2, 3, 4, 5, 6, 7, 8, 9])
  end
end
