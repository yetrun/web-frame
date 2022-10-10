# frozen_string_literal: true

require_relative 'route_dsl/route_builder'
require_relative 'route_dsl/application_builder'
require_relative 'application/application'

# 结构组织如下：
# - lib/application.rb: 模块实例
# - route_dsl/application_builder.rb: DSL 语法的 Builder
# - application.rb(本类): 综合以上两个类q的方法到一个类当中
module Dain
  class Application
    class << self
      extend Forwardable

      include Execution::MakeToRackMiddleware

      attr_reader :builder

      def inherited(mod)
        super

        mod.instance_eval { @builder = RouteDSL::ApplicationBuilder.new }
      end

      # 读取应用的元信息
      def_delegators :app, :prefix, :routes, :applications, :execute

      # DSL 调用委托给内部 Builder
      def_delegators :builder, :before, :after, :rescue_error, :route, :apply, :namespace

      def app
        @app || @app = builder.build({})
      end

      def build(*args)
        @app = builder.build(*args)
      end
    end
  end
end
