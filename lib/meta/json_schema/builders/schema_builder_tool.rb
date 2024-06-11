# frozen_string_literal: true

require_relative 'ref_schema_builder'
require_relative 'dynamic_schema_builder'
require_relative 'array_schema_builder'
require_relative 'object_schema_builder'
require_relative '../schemas/staging_schema'

module Meta
  module JsonSchema
    class SchemaBuilderTool
      class << self
        SCHEMA_BUILDER_OPTIONS = Utils::KeywordArgs::Builder.build do
          permit_extras true

          key :ref, alias_names: [:using], normalizer: ->(entity) { entity }
          key :dynamic_ref, alias_names: [:dynamic_using], normalizer: ->(value) { value.is_a?(Proc) ? { resolve: value } : value }
        end
        def build(options = {}, &block)
          options = SCHEMA_BUILDER_OPTIONS.check(options)
          options = fix_type_option(options)

          if options[:param] || options[:render]
            # 让 StagingSchema 位于一级排面上
            StagingSchema.build_from_options(options)
          elsif apply_array_schema?(options, block)
            ArraySchemaBuilder.new(options, &block).to_schema
          elsif apply_ref_schema?(options, block)
            RefSchemaBuilder.new(options).to_schema
          elsif apply_dynamic_schema?(options, block)
            DynamicSchemaBuilder.new(options).to_schema
          elsif apply_object_schema?(options, block)
            ObjectSchemaBuilder.new(options, &block).to_schema
          else
            BaseSchema.new(options)
          end
        end

        private

          def fix_type_option(options)
            if options[:type].is_a?(Class)
              # 修复 type 为自定义类的情形
              options = options.dup
              the_class = options[:type]

              # 修复 param 选项
              if options[:param]
                options[:param] = options[:param].dup
              else
                options[:param] = {}
              end
              if options[:param][:after].nil?
                options[:param][:after] = ->(value) { the_class.new(value) }
              else
                # 如果用户自定义了 after，那么我们需要在 after 之后再包一层
                original_after_block = options[:param][:after]
                options[:param][:after] = ->(value) do
                  value = instance_exec(value, &original_after_block)
                  the_class.new(value)
                end
              end

              # 修复 render 选项
              if options[:render]
                options[:render] = options[:render].dup
              else
                options[:render] = {}
              end
              render_before_block = ->(value) do
                raise ValidationError, "value 必须是 #{the_class} 类型" unless value.is_a?(the_class)
                value
              end
              if options[:render][:before].nil?
                options[:render][:before] = render_before_block
              else
                # 如果用户自定义了 before，那么我们需要在 before 之前再包一层
                original_before_block = options[:render][:before]
                options[:render][:before] = ->(value) do
                  value = render_before_block.call(value)
                  instance_exec(value, &original_before_block)
                end
              end
              options = options.merge(type: 'object')
            end

            options
          end

          def apply_array_schema?(options, block)
            options[:type] == 'array'
          end

          def apply_object_schema?(options, block)
            options[:properties] || block
          end

          def apply_ref_schema?(options, block)
            options[:ref] != nil
          end

          def apply_dynamic_schema?(options, block)
            options[:dynamic_ref] != nil
          end
      end
    end
  end
end
