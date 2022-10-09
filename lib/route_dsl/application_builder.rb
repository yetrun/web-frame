# frozen_string_literal: true

require_relative 'route_builder'

module Dain
  module RouteDSL
    class ApplicationBuilder
      attr_reader :chain, :before_callbacks, :after_callbacks, :error_guards

      def initialize(&block)
        @chain_builder = [] # TODO: 将 Application 的构建和执行也分成两个类
        @before_callbacks = []
        @after_callbacks = []
        @error_guards = []

        instance_exec &block if block_given?
      end

      def build
        @chain = @chain_builder.map(&:build)
        Application.new(@chain, @before_callbacks, @after_callbacks, @error_guards)
      end

      def route(path, method = nil, &block)
        route = RouteDSL::RouteBuilder.new(path, method, &block)
        @chain_builder << route
        route
      end

      def before(&block)
        before_callbacks << block
      end

      def after(&block)
        after_callbacks << block
      end

      def rescue_error(error_class, &block)
        error_guards << { error_class: error_class, caller: block }
      end

      def apply(mod)
        @chain_builder << mod
      end
    end
  end
end
