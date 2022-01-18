# frozen_string_literal: true

# 每个块都是在 execution 环境下执行的

require_relative 'param_scope'
require_relative 'execution'
require 'json'

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
      raise Errors::NotAuthorized unless permitted
    }
  end

  def expose(key = nil, &block)
    do_any {
      entity = instance_exec(&block)

      if key.nil?
        # 直接将 entity 渲染为 response body
        entity_json = entity.respond_to?(:as_json) ? entity.as_json : entity
        response.body = [JSON.generate(entity_json)]
      else
        # 首先获取字符串格式的 response.body
        response_body = response.body
        response_body = response_body[0] if response_body.is_a?(Array)

        # 接着将字符串格式的 body 解释为 Hash
        if response_body.nil? || response_body == ''
          response_hash = {}
        else
          response_hash = JSON.parse(response_body)
        end

        # 最后合并 entity 到 response.body
        response_hash[key.to_s] = entity.respond_to?(:as_json) ? entity.as_json : entity
        response.body = [JSON.generate(response_hash)]
      end
    }
  end

  def expose_resource(key = nil)
    expose(key) { resource }
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
