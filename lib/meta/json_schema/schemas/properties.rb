# frozen_string_literal: true

require 'forwardable'

module Meta
  module JsonSchema
    class Properties
      class StagingProperty
        def initialize(param:, render:, none:)
          @param_stage = param
          @render_stage = render
          @none_stage = none
        end

        def stage(stage = nil)
          case stage
          when :param
            @param_stage
          when :render
            @render_stage
          else
            @none_stage
          end
        end

        def stage?(stage)
          stage(stage) != nil
        end

        def schema(stage = nil)
          stage(stage).schema
        end

        def self.build(options, build_schema)
          param_opts, render_opts, common_opts = SchemaOptions.divide_to_param_and_render(options)

          StagingProperty.new(
            param: options[:param] === false ? nil : ScopingProperty.build(param_opts, build_schema),
            render: options[:render] === false ? nil : ScopingProperty.build(render_opts, build_schema),
            none: ScopingProperty.build(common_opts, build_schema)
          )
        end
      end

      class ScopingProperty
        attr_reader :scope, :schema

        def initialize(scope: :all, schema:)
          scope = :all if scope.nil?
          scope = [scope] unless scope.is_a?(Array) || scope == :all
          if scope.is_a?(Array) && scope.any? { |s| s.is_a?(Integer) }
            raise ArgumentError, 'scope 选项内不可传递数字'
          end
          @scope = scope

          @schema = schema
        end

        def self.build(options, build_schema)
          options = options.dup
          scope = options.delete(:scope)
          schema = build_schema.call(options)
          ScopingProperty.new(scope: scope, schema: schema)
        end
      end

      extend Forwardable

      def initialize(properties)
        @properties = properties
      end

      def filter_by(stage:, user_scope: false)
        properties = @properties.filter do |name, property|
          # 通过 stage 过滤。
          next false unless property.stage?(stage)
          property = property.stage(stage)

          # 通过 user_scope 过滤
          next true if property.scope == :all
          (user_scope - property.scope).empty? # user_scope 应被消耗殆尽
        end
        properties.transform_values do |property|
          property.stage(stage).schema
        end
      end

      # 程序中有些地方用到了这三个方法
      def_delegators :@properties, :empty?, :key?, :[]

      def self.build_property(*args)
        StagingProperty.build(*args)
      end
    end
  end
end
