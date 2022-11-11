# frozen_string_literal: true

module Dain
  class Application
    include Execution::MakeToRackMiddleware
    include PathMatchingMod.new(path_method: :prefix, matching_mode: :prefix)

    attr_reader :prefix, :mods, :before_callbacks, :after_callbacks, :error_guards

    def initialize(options)
      @prefix = options[:prefix] || ''
      @mods = options[:mods] || []
      @shared_mods = options[:shared_mods] || []
      @before_callbacks = options[:before_callbacks] || []
      @after_callbacks = options[:after_callbacks] || []
      @error_guards = options[:error_guards] || []
    end

    def execute(execution, remaining_path = '')
      remaining_path_for_children = path_matching.merge_path_params(remaining_path, execution.request)

      @shared_mods.each { |mod| execution.singleton_class.include(mod) }

      before_callbacks.each { |b| execution.instance_eval(&b) }

      mod = find_child_mod(execution, remaining_path_for_children)
      if mod
        mod.execute(execution, remaining_path_for_children)
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

    def match?(execution, remaining_path)
      return false unless path_matching.match?(remaining_path)

      remaining_path_for_children = path_matching.capture_remaining_part(remaining_path)
      find_child_mod(execution, remaining_path_for_children) != nil
    end

    def applications
      mods.filter { |r| r.is_a?(Application) }
    end

    def routes
      mods.filter { |r| r.is_a?(Route) }
    end

    def to_swagger_doc
      SwaggerDocUtil.generate(self)
    end

    private

    def find_child_mod(execution, remaining_path_for_children)
      mods.find { |mod| mod.match?(execution, remaining_path_for_children) }
    end
  end
end
