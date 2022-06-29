# frozen_string_literal: true

require_relative 'application/class_methods'
require_relative 'route/builder'

module Dain
  class Application
    attr_reader :chain, :before_callbacks, :after_callbacks, :error_guards

    def initialize
      @chain_builder = [] # TODO: 将 Application 的构建和执行也分成两个类

      @chain = []
      @before_callbacks = []
      @after_callbacks = []
      @error_guards = []
    end

    # 所有主函数分两个区，第一个是构建区，类似于 Builder；第二个是执行区，是在构建完成以后作为不可变对象运行。

    ## 执行区

    def execute(execution)
      build

      before_callbacks.each { |b| execution.instance_eval(&b) }

      mod = chain.find { |mod| mod.match?(execution) }
      if mod
        mod.execute(execution)
      else
        request = execution.request
        raise Errors::NoMatchingRoute, "未能发现匹配的路由：#{request.request_method} #{request.path}"
      end

      after_callbacks.each { |b| execution.instance_eval(&b) }
    rescue StandardError => e
      guard = error_guards.find { |g| e.is_a?(g[:error_class]) }
      raise unless guard

      execution.instance_eval(&guard[:caller])
    end

    def match?(execution)
      chain.any? { |mod| mod.match?(execution) }
    end

    def applications
      build and chain.filter { |r| r.is_a?(Application) }
    end

    def routes
      build and chain.filter { |r| r.is_a?(Route) }
    end

    # 定义与 Route 类似的 build 方法
    def build
      return self unless @chain_builder

      @chain = @chain_builder.map(&:build)
      @chain_builder = false

      self
    end

    ## 构建区

    def route(path, method = nil)
      route = Route::Builder.new(path, method)
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
