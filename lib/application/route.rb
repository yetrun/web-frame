# frozen_string_literal: true

# 每个块都是在 execution 环境下执行的

require_relative 'execution'
require_relative 'path_matching_mod'

module Dain
  class Route
    include PathMatchingMod.new(path_method: :path, matching_mode: :full)

    attr_reader :path, :method, :meta, :actions

    def initialize(path: '', method: :all, meta: {}, actions: [])
      @path = Utils::Path.normalize_path(path)
      @method = method
      @meta = meta # REVIEW: meta 用一个对象表示更好？
      @actions = actions
    end

    def execute(execution, remaining_path)
      path_matching.merge_path_params(remaining_path, execution.request)

      # 依次执行这个环境
      begin
        execution.parse_parameters(@meta[:parameters]) if @meta[:parameters]
        execution.parse_params(@meta[:params_schema]) if @meta[:params_schema]

        actions.each { |b| execution.instance_eval(&b) }

        render_entity(execution) if @meta[:responses]
      rescue Execution::Abort
        execution
      end
    end

    def match?(execution, remaining_path)
      request = execution.request
      remaining_path = '' if remaining_path == '/'
      method = request.request_method

      return false unless path_matching.match?(remaining_path)
      return false unless @method == :all || @method.to_s.upcase == method
      return true
    end

    private

    def render_entity(execution)
      responses = @meta[:responses]
      status = execution.response.status
      codes = responses.keys
      return unless codes.include?(status)

      entity_schema = responses[status]
      execution.render_entity(entity_schema)
    end
  end
end
