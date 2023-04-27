# frozen_string_literal: true

require 'json'
require_relative '../entity'
require_relative '../application/route'
require_relative 'helpers'
require_relative 'chain_builder'
require_relative 'action_builder'
require_relative 'meta_builder'
require_relative 'around_action_builder'

module Meta
  module RouteDSL
    class RouteBuilder
      include MetaBuilder::Delegator

      alias :if_status :status

      def initialize(path = '', method = :all, &block)
        @path = path || ''
        @method = method || :all
        @action_builder = nil
        @meta_builder = MetaBuilder.new

        instance_exec &block if block_given?
      end

      def build(parent_path: '', meta: {}, callbacks: {})
        # 合并 meta 时不仅仅是覆盖，比如 parameters 参数需要合并
        meta2 = (meta || {}).merge(@meta_builder.build)
        if meta[:parameters] && meta2[:parameters]
          meta2[:parameters] = meta[:parameters].merge(meta2[:parameters])
        end

        # 合并 parameters 参数
        meta2[:parameters] ||= {}
        path_params = Utils::Path.join(parent_path, @path).split('/')
          .filter { |part| part =~ /[:*].+/ }
          .map { |part| part[1..-1].to_sym }
        path_params.each do |name|
          unless meta2[:parameters].key?(name)
            meta2[:parameters][name] = {
              in: 'path',
              schema: JsonSchema::BaseSchema.new(required: true)
            }
          end
        end

        # 构建洋葱圈模型的 LinkedAction
        # 合并父级传递过来的 callbacks，将 before 和 around 放在前面，after 放在后面
        parent_before = callbacks.filter { |cb| cb[:lifecycle] == :before || cb[:lifecycle] == :around }
        parent_after = callbacks.filter { |cb| cb[:lifecycle] == :after }
        callbacks = parent_before + [{ lifecycle: :before, proc: @action_builder&.build }] + parent_after
        # 使用 AroundActionBuilder 构建洋葱圈模型
        around_action_builder = AroundActionBuilder.new
        callbacks.each do |cb|
          around_action_builder.send(cb[:lifecycle], &cb[:proc]) if cb[:proc]
        end
        action = around_action_builder.build

        Route.new(
          path: @path,
          method: @method,
          meta: meta2,
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

      private

      def clone_meta(meta)
        meta = meta.clone
        meta[:responses] = meta[:responses].clone if meta[:responses]
        meta
      end
    end
  end
end
