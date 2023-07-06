# frozen_string_literal: true

require_relative '../application/parameters'

module Meta
  module RouteDSL
    class ParametersBuilder
      def initialize(route_full_path:, route_method:, &block)
        @route_full_path = route_full_path || ''
        @route_method = route_method
        @parameter_options = {}

        instance_exec &block if block_given?
      end

      def param(name, options = {})
        # 修正 path 参数的选项
        if path_param_names.include?(name) # path 参数
          options = options.merge(in: 'path', required: true)
        else
          options = options.dup
        end
        in_op = options.delete(:in) || 'query'
        @parameter_options[name] = { in: in_op, schema: JsonSchema::BaseSchema.new(options) }
      end

      def build
        # 补充未声明的 path 参数
        (path_param_names - @parameter_options.keys).each do |name|
          @parameter_options[name] = { in: 'path', schema: JsonSchema::BaseSchema.new(required: true) }
        end

        Parameters.new(@parameter_options)
      end

      private

      def path_param_names
        @_path_param_names ||= @route_full_path.split('/')
                                               .filter { |part| part =~ /[:*].+/ }
                                               .map { |part| part[1..-1].to_sym }
      end
    end
  end
end
