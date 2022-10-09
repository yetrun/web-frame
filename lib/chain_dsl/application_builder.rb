# frozen_string_literal: true

require_relative 'route_builder'

module Dain
  class ApplicationBuilder
    attr_reader :chain, :before_callbacks, :after_callbacks, :error_guards

    def initialize
      @chain_builder = [] # TODO: 将 Application 的构建和执行也分成两个类
      @before_callbacks = []
      @after_callbacks = []
      @error_guards = []
    end

    def build
      @chain = @chain_builder.map(&:build)
      Application.new(@chain, @before_callbacks, @after_callbacks, @error_guards)
    end

    def route(path, method = nil)
      route = RouteBuilder.new(path, method)
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
