# frozen_string_literal: true

require_relative 'application_class'
require_relative 'routes'

class Application
  attr_reader :applications, :routes, :before_callbacks, :after_callbacks

  def initialize
    @applications = []
    @routes = Routes.new
    @before_callbacks = []
    @after_callbacks = []
    @error_guards = []
  end

  def execute(execution)
    before_callbacks.each { |b| execution.instance_eval(&b) }

    if routes.match?(execution)
      routes.execute(execution)
    else
      application = applications.find { |app| app.match?(execution) }
      application.execute(execution)
    end

    after_callbacks.each { |b| execution.instance_eval(&b) }
  rescue StandardError => e
    guard = @error_guards.find { |g| e.is_a?(g[:error_class]) }
    raise unless guard

    execution.instance_eval(&guard[:caller])
  end

  def match?(execution)
    return true if routes.match?(execution)

    applications.any? { |app| app.match?(execution) }
  end

  def route(path, method)
    routes.route(path, method)
  end

  def before(&block)
    before_callbacks << block
  end

  def after(&block)
    after_callbacks << block
  end

  def rescue_error(error_class, &block)
    @error_guards << { error_class: error_class, caller: block }
  end

  def apply(mod)
    applications << mod
  end
end
