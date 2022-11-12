# frozen_string_literal: true

require 'json'
require_relative '../entity'
require_relative '../application/route'
require_relative 'helpers'
require_relative 'chain_builder'
require_relative 'action_builder'
require_relative 'meta_builder'

module Dain
  module RouteDSL
    class RouteBuilder
      include MetaBuilder::Delegator

      alias :if_status :status

      def initialize(path = '', method = :all, &block)
        @path = path || ''
        @method = method || :all
        @children = []
        @action_builder = nil
        @meta_builder = MetaBuilder.new

        instance_exec &block if block_given?
      end

      def build(meta)
        children = @children.map { |builder| builder.build(meta) }
        action = @action_builder&.build
        meta = (meta || {}).merge(@meta_builder.build)

        Route.new(
          path: @path,
          method: @method,
          meta: meta,
          action: action,
          children: children
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
