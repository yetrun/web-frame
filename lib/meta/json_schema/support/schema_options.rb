# frozen_string_literal: true

require_relative '../../utils/kwargs/builder'

module Meta
  module JsonSchema
    module SchemaOptions
      BaseBuildOptions = Utils::Kwargs::Builder.build do
        key :type, :items, :description, :presenter, :value, :default, :properties, :convert
        key :validate, :required, :format
        key :enum, alias_names: [:allowable]
        key :ref, alias_names: [:using], normalizer: ->(entity) { entity }
        key :dynamic_ref, alias_names: [:dynamic_using], normalizer: ->(value) { value.is_a?(Proc) ? { resolve: value } : value }
        key :before, :after
        key :if
      end

      module UserOptions
        Common = Utils::Kwargs::Builder.build do
          key :stage
          key :scope, normalizer: ->(value) {
            raise ArgumentError, 'scope 选项不可传递 nil' if value.nil?
            value = [value] unless value.is_a?(Array)
            value.map do |v|
              # 只要加入了 Meta::Scope::Base 模块，就有与 Meta::Scope 一样的行为
              next v if v.is_a?(Meta::Scope::Base)

              # 将 v 类名化
              scope_name = v.to_s.split('_').map(&:capitalize).join
              # 如果符号对应的类名不存在，就报错
              if !defined?(::Scopes) || !::Scopes.const_defined?(scope_name)
                raise NameError, "未找到常量 Scopes::#{scope_name}。如果你用的是命名 Scope（字符串或符号），则检查一下是不是拼写错误"
              end
              # 返回对应的常量
              ::Scopes.const_get(scope_name)
            end.compact
          }

          handle_extras :merged
        end
        ToDoc = Utils::Kwargs::Builder.build(Common) do
          key :schema_docs_mapping, :defined_scopes_mapping
        end
        Filter = Utils::Kwargs::Builder.build(Common) do
          key :discard_missing, :exclude, :extra_properties, :type_conversion, :validation
          key :execution, :user_data, :object_value
        end
      end

      class << self
        def fix_type_option!(options)
          if options[:type].is_a?(Class)
            # 修复 type 为自定义类的情形
            the_class = options[:type]
            # 修复 param 选项
            options[:param] = {} if options[:param].nil?
            make_after_cast_to_class(options[:param], the_class) if options[:param]
            # 修复 render 选项
            options[:render] = {} if options[:render].nil?
            make_before_match_to_class(options[:render], the_class) if options[:render]
            # 最终确保 type 为 object
            options.merge!(type: 'object')
          end
        end

        def divide_to_param_and_render(options)
          common_opts = (options || {}).dup
          param_opts = common_opts.delete(:param)
          render_opts = common_opts.delete(:render)

          param_opts = merge_common_to_stage(common_opts, param_opts)
          render_opts = merge_common_to_stage(common_opts, render_opts)
          [param_opts, render_opts, common_opts]
        end

        private

        def merge_common_to_stage(common_opts, stage_opts)
          stage_opts = {} if stage_opts.nil? || stage_opts == true
          stage_opts = common_opts.merge(stage_opts) if stage_opts
          stage_opts
        end

        def make_after_cast_to_class(options, the_class)
          if options[:after].nil?
            options[:after] = ->(value) { the_class.new(value) }
          else
            # 如果用户自定义了 after，那么我们需要在 after 之后再包一层
            original_after_block = options[:after]
            options[:after] = ->(value) do
              value = instance_exec(value, &original_after_block)
              the_class.new(value)
            end
          end
        end

        def make_before_match_to_class(options, the_class)
          match_class = ->(value) do
            raise ValidationError, "value 必须是 #{the_class} 类型" unless value.is_a?(the_class)
            value
          end
          if options[:before].nil?
            options[:before] = match_class
          else
            # 如果用户自定义了 before，那么我们需要在 before 之前再包一层
            original_before_block = options[:before]
            options[:before] = ->(value) do
              value = match_class.call(value)
              instance_exec(value, &original_before_block)
            end
          end
        end

      end
    end
  end
end
