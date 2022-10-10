# frozen_string_literal: true

require_relative 'route_builder'

module Dain
  module RouteDSL
    class ApplicationBuilder
      def initialize(prefix = nil, &block)
        @prefix = prefix
        @chain_builder = [] # TODO: 将 Application 的构建和执行也分成两个类
        @before_callbacks = []
        @after_callbacks = []
        @error_guards = []

        instance_exec &block if block_given?
      end

      def build
        @chain = @chain_builder.map(&:build)
        Application.new(
          prefix: @prefix,
          mods: @chain,
          before_callbacks: @before_callbacks,
          after_callbacks: @after_callbacks,
          error_guards: @error_guards
        )
      end

      def route(path, method = nil, &block)
        path = join_path(@prefix, path)
        route_builder = RouteDSL::RouteBuilder.new(path, method, &block)
        @chain_builder << route_builder
        route_builder
      end

      def before(&block)
        @before_callbacks << block
      end

      def after(&block)
        @after_callbacks << block
      end

      def rescue_error(error_class, &block)
        @error_guards << { error_class: error_class, caller: block }
      end

      def namespace(path, &block)
        path = join_path(@prefix, path)
        @chain_builder << ApplicationBuilder.new(path, &block)
      end

      def apply(builder)
        @chain_builder << builder
      end

      private

      def join_path(*parts)
        parts = parts.filter { |p| p }
        parts = parts.map { |p| p.delete_prefix('/').delete_suffix('/') }
        '/' + parts.join('/')
      end
    end
  end
end
