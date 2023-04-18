# frozen_string_literal: true

require_relative '../application/linked_action'

module Meta
  module RouteDSL
    class AroundActionBuilder
      def initialize
        @around = []
      end

      def around(&block)
        @around << block
      end

      def build
        # 从后向前构建
        @around.reverse.reduce(nil) do |following, p|
          LinkedAction.new(p, following)
        end
      end

      # 使用 before、after、around 系列和当前 action 共同构建洋葱圈模型。
      # 构建成功后，执行顺序是：
      #
      # - before 序列
      # - around 序列的前半部分
      # - action
      # - around 序列的后半部分
      # - after 序列
      #
      def self.build(before: [], after: [], around: [], action: nil)
        builder = AroundActionBuilder.new

        # 首先构建 before 序列，保证它最先执行
        builder.around do |next_action|
          before.each { |p| self.instance_exec(&p) }
          next_action.execute(self)
        end unless before.empty?
        # 然后构建 after 序列，保证它最后执行
        builder.around do |next_action|
          next_action.execute(self)
          after.each { |p| self.instance_exec(&p) }
        end unless after.empty?
        # 接着应用洋葱圈模型，依次构建 around 序列、action
        around.each { |p| builder.around(&p) }
        builder.around { self.instance_exec(&action) } unless action.nil?

        builder.build
      end
    end
  end
end
