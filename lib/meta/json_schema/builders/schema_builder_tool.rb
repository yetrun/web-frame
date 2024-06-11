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
        def build(options = {}, &block)
          options = SchemaOptions::BaseBuildOptions.check(options)
          SchemaOptions.fix_type_option!(options)

          if apply_staging_schema?(options)
            # 原则上，SchemaBuilderTool 不处理 param render scope 选项，这几个选项只会在 property 宏中出现，
            # 并且交由 StagingSchema 和 ScopingSchema 专业处理。
            # 只不过，经过后置修复后可能包含了 param 和 render 选项
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

          def apply_staging_schema?(options)
            if options.key?(:param)
              return true if options[:param] == false || !options[:param].empty?
            end
            if options.key?(:render)
              return true if options[:render] == false || !options[:render].empty?
            end
            false
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
