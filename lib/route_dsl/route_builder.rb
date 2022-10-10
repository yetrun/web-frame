# frozen_string_literal: true

require 'json'
require_relative '../entity'
require_relative '../application/route'
require_relative 'chain_builder'
require_relative 'action_builder'

module Dain
  module RouteDSL
    class RouteBuilder
      extend Forwardable

      def initialize(path = :all, method = :all, &block)
        @path = path || :all
        @method = method || :all
        @meta = {}
        @children = []
        @action_builder = nil

        instance_exec &block if block_given?
      end

      def build
        children = @children.map { |builder| builder.build }
        action = @action_builder&.build

        Route.new(
          path: @path,
          method: @method,
          meta: @meta,
          action: action,
          children: children
        )
      end

      # 定义子路由
      # TODO: 使用构建器
      def method(method, path = nil)
        route = RouteBuilder.new(path, method)
        @children << route

        route
      end

      def route(path = :all, method = :all, &block)
        route = RouteBuilder.new(path, method, &block)
        @children << route
        route
      end

      def nesting(&block)
        instance_eval(&block)

        nil
      end

      def chain
        @action_builder || @action_builder = ChainBuilder.new
      end

      def action(&block)
        @action_builder = ActionBuilder.new(&block)
      end

      def params(options = {}, &block)
        @meta[:params_schema] = JsonSchema::BaseSchemaBuilder.build(options, &block)

        self
      end

      def status(code, *other_codes, &block)
        codes = [code, *other_codes]
        entity_schema = JsonSchema::BaseSchemaBuilder.build(&block).to_schema
        @meta[:responses] = @meta[:responses] || {}
        codes.each { |code| @meta[:responses][code] = entity_schema }

        self
      end

      alias :if_status :status

      # 定义 meta 元信息设置的方法
      [:tags, :title, :description].each do |method_name|
        define_method(method_name) do |value|
          @meta[method_name] = value
          self
        end
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
