# frozen_string_literal: true

require_relative 'route_builder'
require_relative 'meta_builder'
require_relative '../utils/route_dsl_builders'

module Meta
  module RouteDSL
    class ApplicationBuilder
      include MetaBuilder::Delegator

      # TODO: prefix 改为 ''
      # prefix 貌似是完整的
      def initialize(prefix = '', &block)
        @mod_prefix = prefix
        @callbacks = []
        @error_guards = []
        @meta_builder = MetaBuilder.new(route_full_path: prefix)
        @mod_builders = []
        @shared_mods = []

        instance_exec &block if block_given?
      end

      # TODO: parent_path 没有用的上, meta -> meta_options
      # meta 和 callbacks 是父级传递过来的，需要合并到当前模块或子模块中。
      #
      # 为什么一定要动态传递 meta_options 参数？由于 OpenAPI 文档是面向路由的，parameters、request_body、
      # responses 都存在于路由文档中，对应地 Metadata 对象最终只存在于路由文档中。因此，在构建过程中，需要将父
      # 级传递过来的 Metadata 对象合并到当前模块，再层层合并到子模块。
      def build(meta_options: {}, callbacks: [])
        meta_options = Utils::RouteDSLBuilders.merge_meta_options(meta_options, @meta_builder.build)
        callbacks = Utils::RouteDSLBuilders.merge_callbacks(callbacks, @callbacks)
        mods = @mod_builders.map { |builder| builder.build(meta_options: meta_options, callbacks: callbacks) }

        Application.new(
          prefix: @mod_prefix,
          mods: mods,
          shared_mods: @shared_mods,
          error_guards: @error_guards
        )
      end

      def shared(*mods, &block)
        @shared_mods += mods
        @shared_mods << Module.new(&block) if block_given?
      end

      # 定义路由块
      def route(path, method = nil, &block)
        route_builder = RouteBuilder.new(path, method, parent_path: @mod_prefix, &block)
        @mod_builders << route_builder
        route_builder
      end

      # 定义子模块
      def namespace(path, &block)
        @mod_builders << ApplicationBuilder.new(path, &block)
      end

      # 应用另一个模块
      def apply(builder, tags: nil)
        @mod_builders << BindingMeta.new(builder, tags ? { tags: tags } : {})
      end

      # 定义模块内的公共逻辑
      def before(&block)
        @callbacks << {
          lifecycle: :before,
          proc: block
        }
      end

      def after(&block)
        @callbacks << {
          lifecycle: :after,
          proc: block
        }
      end

      def around(&block)
        @callbacks << {
          lifecycle: :around,
          proc: block
        }
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

      # 绑定 Meta，绑定的 Meta 会覆盖父级的 Meta，用于 Application.apply 方法
      class BindingMeta
        def initialize(builder, meta)
          @builder = builder
          @meta = meta
        end

        def build(meta_options: {}, **kwargs)
          meta_options = Utils::RouteDSLBuilders.merge_meta_options(meta_options, @meta)
          @builder.build(meta_options: meta_options, **kwargs)
        end
      end
    end
  end
end
