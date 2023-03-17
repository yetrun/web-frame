# frozen_string_literal: true

require_relative '../../utils/kwargs/builder'

module Meta
  module JsonSchema
    module SchemaOptions
      OPTIONS_CHECKER = Utils::KeywordArgs::Builder.build do
        key :type, :items, :description, :presenter, :value, :format, :required, :default, :validate, :allowable, :properties, :convert
        # key :scope, normalizer: ->(value) { value.is_a?(Array) ? value : [value] }
        key :using, normalizer: ->(value) { value.is_a?(Proc) ? { resolve: value } : value }
        key :param
        key :render
      end

      @default_options = {
        scope: [],
        required: false
      }
      @allowable_options = (
        %i[type description in value using default presenter convert scope items using] +
        @default_options.keys + 
        JsonSchema::Validators.keys
      ).uniq

      class << self
        def divide_to_param_and_render(options)
          common_opts = (options || {}).dup
          param_opts = common_opts.delete(:param)
          render_opts = common_opts.delete(:render)

          param_opts = merge_common_to_stage(common_opts, param_opts)
          render_opts = merge_common_to_stage(common_opts, render_opts)
          [param_opts, render_opts, common_opts]
        end

        def normalize(options)
          options = OPTIONS_CHECKER.check(options)

          # 只要 options 中设置为 nil 的选项没有明确的意义，则下行代码是永远有效的
          options = (@default_options.compact).merge(options.compact)
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

        private

        def merge_common_to_stage(common_opts, stage_opts)
          stage_opts = {} if stage_opts.nil? || stage_opts == true
          stage_opts = common_opts.merge(stage_opts) if stage_opts
          stage_opts
        end
      end
    end
  end
end
