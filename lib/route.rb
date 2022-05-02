# frozen_string_literal: true

# 每个块都是在 execution 环境下执行的

require_relative 'entities/scope_builders'
require_relative 'execution'
require 'json'

class Route
  attr_reader :path, :method, :meta, :children

  def initialize(path = :all, method = :all)
    @path = path || :all
    @method = method || :all

    @meta = {}
    @children = []
    @blocks = []
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

  # 定义子路由
  # TODO: 使用构建器
  def define_method(method)
    route = Route.new(nil, method)
    children << route

    route
  end

  def nesting(&block)
    instance_eval(&block)

    nil
  end

  def do_any(&block)
    @blocks << block

    self
  end

  def params(&block)
    param_scope = Entities::ObjectScopeBuilder.new(&block).to_scope
    meta[:param_scope] = param_scope

    do_any {
      request_body = request.body.read
      json = request_body.empty? ? {} : JSON.parse(request_body)
      json.merge!(request.params)

      begin
        params = param_scope.filter(json, '', nil, stage: :param) # TODO: execution 改成 self 可否？
      rescue Errors::EntityInvalid => e
        raise Errors::ParameterInvalid.new(e.errors)
      end

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

  # def if_status(code, &block)
  #   entity_scope = EntityScope.new(&block)

  #   meta[:responses] = meta[:responses] || {}
  #   meta[:responses][code] = entity_scope

  #   do_any {
  #     response.body = [entity_scope.generate_json(self)] if response.status == code
  #   }
  # end

  def if_status(code, &block)
    entity_scope = Entities::ObjectScopeBuilder.new(&block).to_scope

    meta[:responses] = meta[:responses] || {}
    meta[:responses][code] = entity_scope

    do_any {
      next unless response.status == code

      # 首先获取 JSON 响应值
      if @render
        hash = @render[:value]
        options = @render[:options]
      else
        response_body = response.body ? response.body[0] : nil
        hash = response_body ? JSON.parse(response_body) : {}
        options = {}
      end

      # scope_filter = options[:scope] ? options[:scope] : []
      # scope_filter = [scope_filter] unless scope_filter.is_a?(Array)
      # scope_filter << 'return' unless scope_filter.include?('return')
      # options[:scope] = scope_filter

      begin
        new_hash = entity_scope.filter(hash, '', self, stage: :render, **options)
      rescue Errors::EntityInvalid => e
        raise Errors::RenderingInvalid.new(e.errors)
      end
      response.body = [JSON.generate(new_hash)]
    }
  end

  def set_status(&block)
    do_any {
      response.status = instance_exec(&block)
    }
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
