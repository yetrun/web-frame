# frozen_string_literal: true

module Meta
  module RouteDSL
    class UniformedParamsBuilder
      def initialize(&block)
        @parameter_options = {}

        instance_exec &block if block_given?
      end

      def param(name, options = {}, &block)
        @parameter_options[name] = { options: options, block: block }
      end

      def property(name, options = {}, &block)
        @parameter_options[name] = { options: options.merge(in: 'body'), block: block }
      end

      def build(path:, method:)
        # 修正 path 参数的选项
        path_params = path.split('/')
                          .filter { |part| part =~ /[:*].+/ }
                          .map { |part| part[1..-1].to_sym }
        path_params.each do |name|
          @parameter_options[name] ||= {}
          @parameter_options[name][:in] = 'path'
          @parameter_options[name][:required] = true
        end

        # 分门别类构建 parameters 和 request body
        parameters_builder = ParametersBuilder.new
        request_body_builder = JsonSchema::ObjectSchemaBuilder.new
        @parameter_options.each do |name, options|
          param_options = (options[:options] || {}).dup
          param_options[:in] ||= method == :get ? 'query' : 'body' # path 参数保证已处理
          block = options[:block]
          if param_options[:in] == 'body'
            param_options.delete(:in)
            request_body_builder.property name, param_options, &block
          else
            parameters_builder.param name, param_options
          end
        end

        # 返回最终生成的 parameters 和 request body
        parameters = parameters_builder.build(path: path, method: method)
        request_body = request_body_builder.to_schema
        [parameters, request_body.properties.empty? ? nil : request_body]
      end
    end
  end
end
