# frozen_string_literal: true

require_relative 'parameters_builder'
require_relative 'uniformed_params_builder'

module Meta
  module RouteDSL
    class MetaBuilder
      def initialize(&block)
        @meta = {}
        @parameters_builder = ParametersBuilder.new # 默认给一个空的参数构建器，它只会处理 path 参数

        instance_exec &block if block_given?
      end

      def build(path:)
        meta = @meta
        meta[:parameters], meta[:request_body] = @uniformed_params_builder.build(path: path) if @uniformed_params_builder
        meta[:parameters] = @parameters_builder.build(path: path) if meta[:parameters].nil?
        meta
      end

      def parameters(&block)
        @parameters_builder = ParametersBuilder.new(&block)
      end

      def request_body(options = {}, &block)
        @meta[:request_body] = JsonSchema::SchemaBuilderTool.build(options, &block)
      end

      # params 宏是一个遗留的宏，它在一个宏定义块内同时定义 parameters 和 request_body
      def params(&block)
        @uniformed_params_builder = UniformedParamsBuilder.new(&block)
      end

      def status(code, *other_codes, &block)
        codes = [code, *other_codes]
        entity_schema = JsonSchema::SchemaBuilderTool.build(&block)
        @meta[:responses] = @meta[:responses] || {}
        codes.each { |code| @meta[:responses][code] = entity_schema }
      end

      [:tags, :title, :description].each do |method_name|
        define_method(method_name) do |value|
          @meta[method_name] = value
        end
      end

      # 别的模块引入该模块时可直接调用 MetaBuilder 的方法。
      # 由于该模块是动态实现的，其务必要在 MetaBuilder 类构建完毕后再声明，故而放在文件的最后声明。
      module Delegator
        method_names = MetaBuilder.public_instance_methods(false) - ['build']
        method_names.each do |method_name|
          define_method(method_name) do |*args, &block|
            @meta_builder.send(method_name, *args, &block) and self
          end
        end
      end
    end
  end
end
