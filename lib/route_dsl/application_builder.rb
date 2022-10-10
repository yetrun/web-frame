# frozen_string_literal: true

require_relative 'route_builder'
require_relative 'meta_builder'

module Dain
  module RouteDSL
    class ApplicationBuilder
      include MetaBuilder::Delegator

      def initialize(prefix = nil, &block)
        @prefix = prefix
        @chain_builder = [] # TODO: 将 Application 的构建和执行也分成两个类
        @before_callbacks = []
        @after_callbacks = []
        @error_guards = []
        @meta_builder = MetaBuilder.new

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

      # 定义路由块
      def route(path, method = nil, &block)
        path = join_path(@prefix, path)
        route_builder = RouteDSL::RouteBuilder.new(path, method, @meta_builder.build, &block)
        @chain_builder << route_builder
        route_builder
      end

      # 定义子模块
      def namespace(path, &block)
        path = join_path(@prefix, path)
        @chain_builder << ApplicationBuilder.new(path, &block)
      end

      # 应用另一个模块
      def apply(builder)
        @chain_builder << builder
      end

      # 定义模块内的公共逻辑
      def before(&block)
        @before_callbacks << block
      end

      def after(&block)
        @after_callbacks << block
      end

      def rescue_error(error_class, &block)
        @error_guards << { error_class: error_class, caller: block }
      end

      # 定义应用到子模块的公共逻辑
      def meta(&block)
        @meta_builder.instance_exec &block
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
