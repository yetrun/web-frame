# frozen_string_literal: true

module Dain
  module RouteDSL
    class ChainBuilder
      def initialize
        @blocks = []
      end

      def build
        blocks = @blocks
        proc do
          blocks.each { |b| instance_exec &b }
        end
      end

      def do_any(&block)
        @blocks << block

        self
      end

      def resource(&block)
        do_any {
          resource = instance_exec(&block)

          raise Errors::NotFound if resource.nil?

          # 为 execution 添加一个 resource 方法
          define_singleton_method(:resource) { resource }
        }
      end

      def authorize(&block)
        do_any {
          permitted = instance_eval(&block)
          raise Errors::NotAuthorized unless permitted
        }
      end

      def set_status(&block)
        do_any {
          response.status = instance_exec(&block)
        }
      end
    end
  end
end
