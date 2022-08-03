# frozen_string_literal: true

module Dain
  module JsonSchema
    module SchemaOptions
      @default_options = {
        in: 'body',
        scope: []
      }

      class << self
        def normalize_to_param_and_render(options)
          common_opts = (options || {}).dup
          param_opts = common_opts.delete(:param)
          render_opts = common_opts.delete(:render)

          param_opts = merge_common_to_stage(common_opts, param_opts)
          render_opts = merge_common_to_stage(common_opts, render_opts)
          [param_opts, render_opts]
        end

        def merge_common_to_stage(common_opts, stage_opts)
          stage_opts = {} if stage_opts.nil? || stage_opts == true
          stage_opts = common_opts.merge(stage_opts) if stage_opts
          stage_opts = normalize(stage_opts) if stage_opts
          stage_opts
        end

        def normalize(options)
          # 只要 options 中设置为 nil 的选项没有明确的意义，则下行代码是永远有效的
          options = @default_options.merge(options.compact)
          options[:scope] = [options[:scope]] unless options[:scope].is_a?(Array)

          options
        end
      end
    end
  end
end
