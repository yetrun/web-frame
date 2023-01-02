# frozen_string_literal: true

module Meta
  module JsonSchema
    module SchemaOptions
      @default_options = {
        scope: [],
        required: false
      }
      @allowable_options = (
        %i[type description in value using default presenter convert scope items] +
        @default_options.keys + 
        JsonSchema::Validators.keys
      ).uniq

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
          options = (@default_options.compact).merge(options.compact)
          options[:scope] = [options[:scope]] unless options[:scope].is_a?(Array)
          if options[:using]
            if options[:type].nil?
              options[:type] = 'object'
            elsif options[:type] != 'object' && options[:type] != 'array'
              raise "当使用 using 时，type 必须声明为 object 或 array"
            end
          end

          # 处理 validators
          unknown_validators = options.keys - @allowable_options
          raise "未知的选项：#{unknown_validators.join(', ')}" unless unknown_validators.empty?

          options
        end
      end
    end
  end
end
