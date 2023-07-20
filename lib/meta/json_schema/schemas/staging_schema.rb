# frozen_string_literal: true

require_relative '../../utils/kwargs/check'
require_relative '../support/schema_options'
require_relative 'scoping_schema'
require_relative 'unsupported_schema'

module Meta
  module JsonSchema
    # 内含 param_schema, render_schema, default_schema，分别用于不同的阶段。
    class StagingSchema < BaseSchema
      attr_reader :param_schema, :render_schema, :default_schema

      def initialize(param_schema:, render_schema:, default_schema:)
        raise ArgumentError, 'param_schema 选项重复提交为 StagingSchema' if param_schema.is_a?(StagingSchema)
        raise ArgumentError, 'render_schema 选项重复提交为 StagingSchema' if render_schema.is_a?(StagingSchema)
        raise ArgumentError, 'default_schema 选项重复提交为 StagingSchema' if default_schema.is_a?(StagingSchema)

        @param_schema = param_schema
        @render_schema = render_schema
        @default_schema = default_schema
      end

      def filter(value, user_options = {})
        if user_options[:stage] == :param
          param_schema.filter(value, user_options)
        elsif user_options[:stage] == :render
          render_schema.filter(value, user_options)
        else
          default_schema.filter(value, user_options)
        end
      end

      def staged(stage)
        if stage == :param
          param_schema
        elsif stage == :render
          render_schema
        else
          default_schema
        end
      end

      def self.build_from_options(options, build_schema = ->(opts) { BaseSchema.new(opts) })
        if (options[:param].is_a?(Hash) || options[:param] == false) ||
           (options[:render].is_a?(Hash) || options[:render] == false)
          param_opts, render_opts, common_opts = SchemaOptions.divide_to_param_and_render(options)
          StagingSchema.new(
            param_schema: options[:param] === false ? UnsupportedSchema.new(:stage, :param) : ScopingSchema.build_from_options(param_opts, build_schema),
            render_schema: options[:render] === false ? UnsupportedSchema.new(:stage, :render) : ScopingSchema.build_from_options(render_opts, build_schema),
            default_schema: ScopingSchema.build_from_options(common_opts, build_schema),
          )
        else
          return ScopingSchema.build_from_options(options, build_schema)
        end
      end
    end
  end
end
