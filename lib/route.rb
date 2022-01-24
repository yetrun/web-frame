# frozen_string_literal: true

# 每个块都是在 execution 环境下执行的

require_relative 'param_scope'
require_relative 'output_scope'
require_relative 'execution'
require 'json'

class Route
  attr_reader :path, :method, :meta

  def initialize(path, method)
    @path = path
    @method = method.to_s.upcase
    @meta = {}
    @blocks = []
  end

  def match?(request)
    path = request.path
    method = request.request_method

    path_matching_regex.match?(path) && @method == method
  end

  def do_any(&block)
    @blocks << block

    self
  end

  def params(&block)
    param_scope = HashParamScope.new(&block)
    meta[:param_scope] = param_scope

    do_any {
      request_body = request.body.read
      json = request_body.empty? ? {} : JSON.parse(request_body)
      json.merge!(request.params)

      params = param_scope.filter(json)

      request.body.rewind

      define_singleton_method(:params) { params }
    }
  end

  def resource(&block)
    do_any {
      resource = instance_exec(&block)

      # 为 execution 添加一个 resource 方法
      define_singleton_method(:resource) { resource }
    }
  end

  def authorize(&block)
    do_any {
      permitted = instance_eval(&block)
      raise Errors::NotAuthorized unless permitted
    }
  end

  def status(code)
    do_any {
      response.status = code
    }
  end

  def outputs(&block)
    output_scope = OutputScope.new(&block)
    meta[:output_scope] = output_scope

    do_any {
      response.body = [output_scope.generate_json(self)]
    }
  end

  def execute(execution)
    # 将 path params 合并到 request 中
    path_params = path_matching_regex.match(execution.request.path).named_captures
    path_params.each { |name, value| execution.request.update_param(name, value) }

    # 依次执行这个环境
    begin
      @blocks.each do |b|
        execution.instance_eval(&b)
      end
    rescue Execution::Abort
      execution
    end
  end

  def tags(names)
    meta[:tags] = names

    self
  end

  def title(title)
    meta[:title] = title

    self
  end

  def description(description)
    meta[:description] = description

    self
  end

  private

  def path_matching_regex
    raw_regex = @path
      .gsub(/:(\w+)/, '(?<\1>[^/]+)').gsub(/\*(\w+)/, '(?<\1>.+)')
      .gsub(/:/, '[^/]+').gsub('*', '.+')
    Regexp.new("^#{raw_regex}$")
  end
end
