# frozen_string_literal: true

module Meta
  module RouteDSL
    class UniformedParamsBuilder
      def initialize(route_full_path:, route_method:, &block)
        @route_full_path = route_full_path
        @route_method = route_method
        @parameters_builder = ParametersBuilder.new(route_full_path: @route_full_path, route_method: @route_method)

        @parameter_options = {}

        instance_exec &block if block_given?
      end

      def param(name, options = {}, &block)
        options = (options || {}).dup
          if path_param_names.include?(name)
            options = Utils::KeywordArgs::Checker.fix!(options, in: 'path', required: true)
          elsif @route_method == :get
            options = Utils::KeywordArgs::Checker.merge_defaults!(options, in: 'query')
          else
            options = Utils::KeywordArgs::Checker.merge_defaults!(options, in: 'body')
          end

        if options[:in] == 'body'
          options.delete(:in)
          property name, options, &block
        else
          @parameters_builder.param name, options
        end
      end

      def property(name, options = {}, &block)
        @request_body_builder ||= JsonSchema::ObjectSchemaBuilder.new
        @request_body_builder.property name, options, &block
      end

      def build
        [@parameters_builder.build, @request_body_builder&.to_schema]
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
