# frozen_string_literal: true
require_relative '../application/parameters'

module Meta
  module RouteDSL
    class ParametersBuilder
      def initialize(&block)
        @parameter_options = {}

        instance_exec &block if block_given?
      end

      def param(name, options = {})
        @parameter_options[name] = options.dup
      end

      def build(path:)
        raise ArgumentError, 'path 参数不能为空' if path.nil?

        # 修正 path 参数的选项
        path_params = path.split('/')
          .filter { |part| part =~ /[:*].+/ }
          .map { |part| part[1..-1].to_sym }
        path_params.each do |name|
          @parameter_options[name] ||= {}
          @parameter_options[name][:in] = 'path'
          @parameter_options[name][:required] = true
        end

        # 构建 Parameters 对象
        parameters = @parameter_options.map do |name, options|
          in_op = options.delete(:in)
          parameter_options = { in: in_op, schema: JsonSchema::BaseSchema.new(options) }
          [name, parameter_options]
        end.to_h
        Parameters.new(parameters)
      end
    end
  end
end
