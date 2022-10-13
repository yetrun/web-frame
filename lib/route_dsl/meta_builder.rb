# frozen_string_literal: true

module Dain
  module RouteDSL
    class MetaBuilder
      # TODO: meta 参数没必要了
      def initialize(&block)
        @meta = {}

        instance_exec &block if block_given?
      end

      def build
        @meta
      end

      def params(options = {}, &block)
        @meta[:params_schema] = JsonSchema::BaseSchemaBuilder.build(options, &block)
      end

      def status(code, *other_codes, &block)
        codes = [code, *other_codes]
        entity_schema = JsonSchema::BaseSchemaBuilder.build(&block)
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
