# frozen_string_literal: true

require_relative 'route_builder'
require_relative 'meta_builder'

module Dain
  module RouteDSL
    class ApplicationBuilder
      include MetaBuilder::Delegator

      def initialize(prefix = nil, &block)
        @mod_prefix = prefix
        @before_callbacks = []
        @after_callbacks = []
        @error_guards = []
        @meta_builder = MetaBuilder.new
        @mod_builders = []
        @shared_mods = []

        instance_exec &block if block_given?
      end

      def build(meta)
        meta = (meta || {}).merge(@meta_builder.build)
        mods = @mod_builders.map { |builder| builder.build(meta) }

        Application.new(
          prefix: @mod_prefix,
          mods: mods,
          shared_mods: @shared_mods,
          before_callbacks: @before_callbacks,
          after_callbacks: @after_callbacks,
          error_guards: @error_guards
        )
      end

      def shared(*mods, &block)
        @shared_mods += mods
        @shared_mods << Module.new(&block) if block_given?
      end

      # 定义路由块
      def route(path, method = nil, &block)
        route_builder = RouteDSL::RouteBuilder.new(path, method, &block)
        @mod_builders << route_builder
        route_builder
      end

      # 定义子模块
      def namespace(path, &block)
        @mod_builders << ApplicationBuilder.new(path, &block)
      end

      # 应用另一个模块
      def apply(builder, options = {})
        tags = options[:tags]
        if tags
          builder = BindingTags.new(builder, tags)
          @mod_builders << builder
        else
          @mod_builders << builder
        end
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

      # 添加 get、post、put、patch、delete 路由方法
      [:get, :post, :put, :patch, :delete].each do |method|
        define_method(method) do |path = '', &block|
          route(path, method, &block)
        end
      end

      class BindingTags
        def initialize(builder, tags)
          @builder = builder
          @tags = tags
        end

        def build(_meta)
          @builder.build({ tags: @tags })
        end
      end
    end
  end
end
