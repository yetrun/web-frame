# frozen_string_literal: true

# 每个块都是在 execution 环境下执行的

require_relative 'execution'

module Dain
  class Route
    attr_reader :path, :method, :meta, :children

    def initialize(options)
      @path = options[:path] || :all
      @method = options[:method] || :all
      @meta = options[:meta] || {}
      @action = options[:action]
      @children = options[:children] || []
    end

    def execute(execution, remaining_path)
      # 将 path params 合并到 request 中
      unless @path == :all
        path_params = path_matching_regex.match(remaining_path).named_captures
        path_params.each { |name, value| execution.request.update_param(name, value) }
      end

      # 依次执行这个环境
      begin
        execution.parse_params(@meta[:params_schema]) if @meta[:params_schema]
        execution.instance_exec(&@action) if @action
        render_entity(execution) if @meta[:responses]
      rescue Execution::Abort
        execution
      end
    end

    def match?(execution, remaining_path)
      request = execution.request
      path = remaining_path
      method = request.request_method

      return false unless @path == :all || path_matching_regex.match?(path)
      return false unless @method == :all || @method.to_s.upcase == method
      return true
    end

    private

    def path_matching_regex
      raw_regex = @path
        .gsub(/:(\w+)/, '(?<\1>[^/]+)').gsub(/\*(\w+)/, '(?<\1>.+)')
        .gsub(/:/, '[^/]+').gsub('*', '.+')
      Regexp.new("^#{raw_regex}$")
    end

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
