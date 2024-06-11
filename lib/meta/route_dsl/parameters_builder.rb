# frozen_string_literal: true

require_relative '../application/parameters'
require_relative '../utils/kwargs/helpers'

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
        options = options.dup
        if path_param_names.include?(name) # path 参数
          options = Utils::Kwargs::Helpers.fix!(options, in: 'path', required: true)
        else
          options = Utils::Kwargs::Helpers.merge_defaults!(options, in: 'query')
        end

        in_op = options.delete(:in)
        raise ArgumentError, "in 选项只能是 path, query, header, body" unless %w[path query header body].include?(in_op)
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
