# frozen_string_literal: true

require_relative 'chain_dsl/route_builder'
require_relative 'chain_dsl/application_builder'
require_relative 'application/application'

# 结构组织如下：
# - lib/application.rb: 模块实例
# - chain_dsl/application_builder.rb: DSL 语法的 Builder
# - application.rb(本类): 综合以上两个类q的方法到一个类当中
module Dain
  class Application
    class << self
      extend Forwardable

      include Execution::MakeToRackMiddleware

      attr_reader :builder

      def inherited(mod)
        super

        mod.instance_eval { @builder = ApplicationBuilder.new }
      end

      # 读取应用的元信息
      def_delegator :app, :routes
      def_delegator :app, :applications
      def_delegator :app, :execute

      # DSL 调用委托给内部 Builder
      def_delegator :builder, :route
      def_delegator :builder, :before
      def_delegator :builder, :after
      def_delegator :builder, :rescue_error
      def_delegator :builder, :apply

      def app
        @app || @app = builder.build
      end

      alias :build :app
    end
  end
end
