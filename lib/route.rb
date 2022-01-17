# frozen_string_literal: true

# 每个块都是在 execution 环境下执行的

require_relative 'param_scope'
require_relative 'execution'

class Route
  def initialize(path, method)
    @path = path
    @method = method.to_s.upcase
    @blocks = []
  end

  def match?(request)
    path = request.path
    method = request.request_method

    path_raw_regex = @path.gsub(/:(\w+)/, '(?<\1>[^/]+)')
    path_regex = Regexp.new("^#{path_raw_regex}$")
    path_regex.match?(path) && @method == method
  end

  def do_any(&block)
    @blocks << block

    self
  end

  def params(&block)
    param_scope = HashParamScope.new(&block)

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
      unless permitted
        response.status = 403
        raise Execution::Abort
      end
    }
  end

  def to_json # rubocop:disable Lint/ToJSON
    do_any {
      response.body = resource.to_json
    }
  end

  def execute(execution)
    # 将 path params 合并到 request 中
    path_raw_regex = @path.gsub(/:(\w+)/, '(?<\1>[^/]+)')
    path_regex = Regexp.new("^#{path_raw_regex}$")
    path_params = path_regex.match(execution.request.path).named_captures
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
end
