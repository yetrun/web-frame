# frozen_string_literal: true

require_relative 'application/class_methods'
require_relative 'route'

class Application
  attr_reader :chain, :before_callbacks, :after_callbacks, :error_guards

  def initialize
    @chain = []
    @before_callbacks = []
    @after_callbacks = []
    @error_guards = []
  end

  def execute(execution)
    before_callbacks.each { |b| execution.instance_eval(&b) }

    mod = chain.find { |mod| mod.match?(execution) }
    mod.execute(execution)

    after_callbacks.each { |b| execution.instance_eval(&b) }
  rescue StandardError => e
    guard = error_guards.find { |g| e.is_a?(g[:error_class]) }
    raise unless guard

    execution.instance_eval(&guard[:caller])
  end

  def match?(execution)
    chain.any? { |mod| mod.match?(execution) }
  end

  def route(path, method)
    route = Route.new(path, method)
    chain << route
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
    chain << mod
  end

  def applications
    chain.filter { |r| r.is_a?(Application) }
  end

  def routes
    chain.filter { |r| r.is_a?(Route) }
  end
end
