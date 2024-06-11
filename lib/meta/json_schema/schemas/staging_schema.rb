# frozen_string_literal: true

require_relative '../support/schema_options'
require_relative 'scoping_schema'
require_relative 'unsupported_schema'

module Meta
  module JsonSchema
    # 内含 param_schema, render_schema, default_schema，分别用于不同的阶段。
    class StagingSchema < BaseSchema
      attr_reader :param_schema, :render_schema

      def initialize(param_schema:, render_schema:)
        raise ArgumentError, 'param_schema 选项重复提交为 StagingSchema' if param_schema.is_a?(StagingSchema)
        raise ArgumentError, 'render_schema 选项重复提交为 StagingSchema' if render_schema.is_a?(StagingSchema)

        @param_schema = param_schema
        @render_schema = render_schema
      end

      def filter(value, user_options = {})
        if user_options[:stage] == :param
          param_schema.filter(value, user_options)
        elsif user_options[:stage] == :render
          render_schema.filter(value, user_options)
        else
          raise ArgumentError, "stage 选项必须是 :param 或 :render"
        end
      end

      def staged(stage)
        if stage == :param
          param_schema
        elsif stage == :render
          render_schema
        else
          raise ArgumentError, "stage 选项必须是 :param 或 :render"
        end
      end

      def defined_scopes(stage:, **kwargs)
        staged(stage).defined_scopes(stage: stage, **kwargs)
      end

      def to_schema_doc(stage:, **kwargs)
        staged(stage).to_schema_doc(stage: stage, **kwargs)
      end

      def self.build_from_options(options, build_schema = ->(opts) { BaseSchema.new(opts) })
        param_opts, render_opts, common_opts = SchemaOptions.divide_to_param_and_render(options)
        if param_opts == common_opts && render_opts == common_opts
          return ScopingSchema.build_from_options(common_opts, build_schema)
        else
          StagingSchema.new(
            param_schema: param_opts ? ScopingSchema.build_from_options(param_opts, build_schema) : UnsupportedSchema.new(:stage, :param),
            render_schema: render_opts ? ScopingSchema.build_from_options(render_opts, build_schema) : UnsupportedSchema.new(:stage, :render)
          )
        end
      end
    end
  end
end
