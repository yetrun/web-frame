# frozen_string_literal: true

# 每个块都是在 execution 环境下执行的

require_relative 'execution'

class Route
  attr_reader :path, :method, :meta, :children

  def initialize(options)
    @path = options[:path] || :all
    @method = options[:method] || :all
    @meta = options[:meta] || {}
    @blocks = options[:blocks] || []
    @children = options[:children] || []
  end

  def execute(execution)
    execute_in_current(execution)

    route = children.find { |route| route.match?(execution) }
    route.execute(execution) if route
  end

  def match?(execution)
    return false unless match_to_current?(execution)
    return children.any? { |route| route.match?(execution) } unless children.empty?

    return true
  end

  private

  def execute_in_current(execution)
    # 将 path params 合并到 request 中
    unless @path == :all
      path_params = path_matching_regex.match(execution.request.path).named_captures
      path_params.each { |name, value| execution.request.update_param(name, value) }
    end

    # 依次执行这个环境
    begin
      @blocks.each do |b|
        execution.instance_eval(&b)
      end
    rescue Execution::Abort
      execution
    end
  end

  def match_to_current?(execution)
    request = execution.request
    path = request.path
    method = request.request_method

    return false unless @path == :all || path_matching_regex.match?(path)
    return false unless @method == :all || @method.to_s.upcase == method
    return true
  end

  def path_matching_regex
    raw_regex = @path
      .gsub(/:(\w+)/, '(?<\1>[^/]+)').gsub(/\*(\w+)/, '(?<\1>.+)')
      .gsub(/:/, '[^/]+').gsub('*', '.+')
    Regexp.new("^#{raw_regex}$")
  end
end
