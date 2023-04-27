# frozen_string_literal: true

# 洋葱圈模型的构建器。
#
# 因为应用的底层仅使用洋葱圈模型，所以在 DSL 层面，我们需要将 before、after、around 等序列和当前 action 共同构建洋葱圈模型。
# 在这个类中，仅仅列出了 before、around、after 三个方法。
# 因此第一步，当前执行的 action 会用 before 逻辑代替。
# 其次，有必要声明 before、after、around 的执行顺序。before 和 after 的顺序关系容易理解，重点是要关注 around 的执行顺序。
# around 的前半部分与 before 的关系：按照声明的顺序执行。
# around 与 after 的关系：after 序列会在之前执行，然后是 around 序列的后半部分。

require_relative '../application/linked_action'

module Meta
  module RouteDSL
    class AroundActionBuilder
      def initialize
        @before = []
        @after = []
      end

      def around(&block)
        @before << block
      end

      def before(&block)
        @before << Proc.new do |next_action|
          self.instance_exec(&block)
          next_action.execute(self) if next_action
        end
      end

      def after(&block)
        # 在洋葱圈模型中，先声明的 after 逻辑会在最后执行，因此为了保证 after 逻辑的执行顺序
        @after.unshift(Proc.new do |next_action|
          next_action.execute(self) if next_action
          self.instance_exec(&block)
        end)
      end

      def build
        # 从后向前构建
        (@before + @after).reverse.reduce(nil) do |following, p|
          LinkedAction.new(p, following)
        end
      end

      # 使用 before、after、around 系列和当前 action 共同构建洋葱圈模型。
      # Note: 该方法可能被废弃!
      #
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
