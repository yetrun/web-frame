# frozen_string_literal: true

require 'json'
require_relative '../entity'
require_relative '../application/route'
require_relative 'chain_builder'
require_relative 'action_builder'
require_relative 'meta_builder'
require_relative 'around_action_builder'

module Meta
  module RouteDSL
    class RouteBuilder
      include MetaBuilder::Delegator

      alias :if_status :status

      # 这里的 path 局部的路径，也就是由 route 宏命令定义的路径
      def initialize(path, method = :all, parent_path: '',&block)
        route_full_path = Utils::Path.join(parent_path, path)

        @path = path || ''
        @method = method || :all
        @action_builder = nil
        @meta_builder = MetaBuilder.new(route_full_path: route_full_path, route_method: method)

        instance_exec &block if block_given?
      end

      def build(meta_options: {}, callbacks: {})
        meta_options = Utils::RouteDSLBuilders.merge_meta_options(meta_options, @meta_builder.build)
        callbacks = Utils::RouteDSLBuilders.merge_callbacks(callbacks, [{ lifecycle: :before, proc: @action_builder&.build }])
        action = AroundActionBuilder.build_from_callbacks(callbacks: callbacks)

        Route.new(
          path: @path,
          method: @method,
          meta: meta_options,
          action: action
        )
      end

      def chain
        @action_builder || @action_builder = ChainBuilder.new
      end

      def action(&block)
        @action_builder = ActionBuilder.new(&block)
      end

      # 将 chain 的方法转交给 ChainBuilder
      [:do_any, :resource, :authorize, :set_status].each do |method_name|
        define_method(method_name) do |&block|
          chain.send(method_name, &block)
          self
        end
      end
    end
  end
end
