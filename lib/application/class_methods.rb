# frozen_string_literal: true

module Dain
  class Application
    class << self
      extend Forwardable

      attr_reader :app

      def inherited(mod)
        super

        mod.instance_eval {
          @app = Application.new
        }
      end

      def call(env)
        # 初始化一个执行环境
        request = Rack::Request.new(env)
        execution = Execution.new(request)

        app.execute(execution)

        response = execution.response
        response.content_type = 'application/json' unless response.no_content?
        response.to_a
      end

      # Swagger 读取元信息用到
      def_delegator :app, :routes
      def_delegator :app, :applications

      # DSL 调用委托给内部 app
      def_delegator :app, :route
      def_delegator :app, :before
      def_delegator :app, :after
      def_delegator :app, :rescue_error

      def apply(mod)
        app.apply(mod.app)
      end
    end
  end
end
