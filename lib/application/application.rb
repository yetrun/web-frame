# frozen_string_literal: true

module Dain
  class Application
    include Execution::MakeToRackMiddleware

    attr_reader :prefix, :mods, :before_callbacks, :after_callbacks, :error_guards

    def initialize(options)
      @prefix = options[:prefix] || nil
      @mods = options[:mods] || []
      @before_callbacks = options[:before_callbacks] || []
      @after_callbacks = options[:after_callbacks] || []
      @error_guards = options[:error_guards] || []
    end

    def execute(execution)
      before_callbacks.each { |b| execution.instance_eval(&b) }

      mod = mods.find { |mod| mod.match?(execution) }
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

      execution.instance_exec(e, &guard[:caller])
    end

    def match?(execution)
      return false unless prefix.nil? || execution.request.path.start_with?(prefix)

      mods.any? { |mod| mod.match?(execution) }
    end

    def applications
      mods.filter { |r| r.is_a?(Application) }
    end

    def routes
      mods.filter { |r| r.is_a?(Route) }
    end
  end
end
