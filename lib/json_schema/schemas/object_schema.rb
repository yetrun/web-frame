# frozen_string_literal: true

module Dain
  module JsonSchema
    class ObjectSchema < BaseSchema
      attr_reader :properties, :object_validations

      def initialize(properties = {}, object_validations = {}, options = {})
        super(options)

        @properties = properties
        @object_validations = object_validations
      end

      def filter(object_value, options = {})
        object_value = super(object_value, options)
        return nil if object_value.nil?

        # 第一步，根据 options[:scope] 需要过滤一些字段
        # options[:scope] 应是一个数组
        scope_filter = options[:scope] || []
        scope_filter = [scope_filter] unless scope_filter.is_a?(Array)
        stage = options[:stage]
        filtered_properties = @properties.filter do |name, scope|
          # 首先通过 stage 过滤。
          next false if stage == :param && !scope.param_options
          next false if stage == :render && !scope.render_options

          # 然后通过 scope 过滤
          scope_options = stage == :param ? scope.param_options : scope.render_options

          # scope_option 是构建 Schema 时传递的 `scope` 选项，它应是一个数组
          # 它与 scope_options 仅一个字母之差，却千壤之别
          scope_option = scope_options[:scope] || []
          scope_option = [scope_option] unless scope_option.is_a?(Array)
          next true if scope_option.empty? # ScopeBuilder 中未声明需要任何的 scope

          # scope_filter 应传递、并且 scope_option 应包含所有的 scope_filter
          !scope_filter.empty? && (scope_filter - scope_option).empty?
        end

        # 第二步，递归过滤每一个属性
        object = {}
        errors = {}
        filtered_properties.each do |name, scope|
          if object_value.is_a?(Hash) 
            value = object_value.key?(name.to_s) ? object_value[name.to_s] : object_value[name.to_sym]
          else
            value = object_value.send(name)
          end

          begin
            object[name] = scope.filter(value, **options)
          rescue JsonSchema::ValidationErrors => e
            errors.merge! e.prepend_root(name).errors
          end
        end.to_h

        if errors.empty?
          object
        else
          raise JsonSchema::ValidationErrors.new(errors)
        end
      end

      # 生成 Swagger 文档的 schema 格式，所谓 schema 格式，是指形如
      #
      #     {
      #       type: 'object',
      #       properties: {
      #         ...
      #       }
      #     }
      #
      # 的格式。
      def to_schema
        properties = @properties.filter { |name, scope|
          scope.options[:in].nil? || scope.options[:in] == 'body' 
        }.transform_values do |scope|
          scope.to_schema
        end

        if properties.empty?
          nil
        else
          schema = {
            type: 'object',
            properties: properties,
          }
          schema[:description] = options[:description] if options[:description]
          schema
        end
      end

      # 生成 Swagger 文档的 parameters 部分，这里是指生成路径位于 `path`、`query`
      # 的参数。
      def generate_parameters_doc
        # 提取根路径的所有 `:in` 选项不为 `body` 的元素（默认值为 `body`）
        scopes = @properties.values.filter { |scope| scope.options[:in] && scope.options[:in] != 'body' }

        scopes.map do |scope|
          scope.generate_parameter_doc
        end
      end
    end
  end
end