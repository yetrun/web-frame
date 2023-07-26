# frozen_string_literal: true

require_relative '../schemas/properties'

module Meta
  module JsonSchema
    class ObjectSchemaBuilder
      module LockedMethodAlias
        # 我在这里说明一下 lock_scope 的逻辑。
        # 1. lock_scope 实际上是将 scope 传递到当前的 ObjectSchema 和它的子 Schema 中。
        # 2. lock_scope 会叠加，也就是如果子 schema 也有 lock_scope，那么子 Schema 会将两个 Schema 合并起来。
        # 3. 调用 filter(scope:) 和 to_schema_doc(scope:) 时，可以传递 scope 参数，这个 scope 遇到 lock_scope 时会合并。
        # 4. 这也就是说，在路由级别定义的 scope 宏会传递到下面的 Schema 中去。
        def add_scope(scope)
          lock_scope(scope)
        end

        def lock(key, value)
          locked(key => value)
        end

        def method_missing(method, *args)
          if method =~ /^lock_(\w+)$/
            key = Regexp.last_match(1)
            lock(key.to_sym, *args)
          else
            super
          end
        end
      end

      def initialize(options = {}, &)
        raise 'type 选项必须是 object' if !options[:type].nil? && options[:type] != 'object'

        @properties = {}
        @required = []
        @validations = {}

        options = options.merge(type: 'object')
        properties = options.delete(:properties)
        @options = options

        properties&.each do |name, property_options|
          property name, property_options
        end

        instance_exec(&) if block_given?
      end

      # 设置 schema_name.
      #
      # 一、可以传递一个块，该块会接收 locked_scope 参数，需要返回一个带有 param 和 render 键的 Hash.
      # 二、可以传递一个 Hash，它包含 param 和 render 键。
      # 三、可以传递一个字符串。
      def schema_name(schema_name_resolver)
        if schema_name_resolver.is_a?(Proc)
          @schema_name_resolver = schema_name_resolver
        elsif schema_name_resolver.is_a?(Hash)
          @schema_name_resolver = proc { |stage, locked_scopes| schema_name_resolver[stage] }
        elsif schema_name_resolver.is_a?(String)
          @schema_name_resolver = proc { |stage, locked_scopes| schema_name_resolver }
        elsif schema_name_resolver.nil?
          @schema_name_resolver = proc { nil }
        else
          raise TypeError, "schema_name_resolver 必须是一个 Proc、Hash 或 String，当前是：#{schema_name_resolver.class}"
        end
      end

      def property(name, options = {}, &block)
        @properties[name.to_sym] = Properties.build_property(options, ->(options) { SchemaBuilderTool.build(options, &block) })
      end

      alias expose property
      alias param property

      # 能且仅能 ObjectSchemaBuilder 内能使用 use 方法
      def use(proc)
        proc = proc.to_proc if proc.respond_to?(:to_proc)
        instance_exec(&proc)
      end

      def to_schema(locked_options = nil)
        ObjectSchema.new(properties: @properties, options: @options, locked_options: locked_options, schema_name_resolver: @schema_name_resolver)
      end

      def locked(options)
        Locked.new(self, options)
      end
      include LockedMethodAlias

      private

      def apply_array_scope?(options, block)
        options[:type] == 'array' && (options[:items] || block)
      end

      def apply_object_scope?(options, block)
        (options[:type] == 'object' || block) && (options[:properties] || block)
      end

      class Locked
        attr_reader :object_schema_builder, :locked_options

        def initialize(builder, locked_options)
          @object_schema_builder = builder
          @locked_options = ObjectSchema::USER_OPTIONS_CHECKER.check(locked_options)
        end

        def to_schema
          object_schema_builder.to_schema(locked_options)
        end

        def locked(options)
          options = ObjectSchema::USER_OPTIONS_CHECKER.check(options)
          options = ObjectSchema.merge_user_options(locked_options, options)
          Locked.new(self.object_schema_builder, options)
        end
        include LockedMethodAlias
      end
    end
  end
end
