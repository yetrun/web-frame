# frozen_string_literal: true

require_relative '../schemas/properties'

module Meta
  module JsonSchema
    class ObjectSchemaBuilder
      extend Forwardable

      class Locked
        # 定义一些 locked 的别名方法
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

        attr_reader :object_schema_builder, :locked_options

        # locked_options 是用户传递的参数，这个参数会被合并到 object_schema_builder 的 locked_options 中。
        def initialize(builder, **locked_options)
          @object_schema_builder = builder
          @locked_options = SchemaOptions::UserOptions::Filter.check(locked_options.compact)
        end

        def to_schema
          object_schema_builder.to_schema(locked_options)
        end

        def locked(options)
          options = SchemaOptions::UserOptions::Filter.check(options)
          options = ObjectSchema.merge_user_options(locked_options, options)
          Locked.new(self.object_schema_builder, **options)
        end
        include LockedMethodAlias
      end

      class WithCommonOptions
        attr_reader :object_schema_builder, :common_options

        def initialize(builder, common_options, &)
          @object_schema_builder = builder
          @common_options = common_options

          instance_exec(&) if block_given?
        end

        def property(name, options = {}, &block)
          options = merge_options(options)
          object_schema_builder.property(name, options, &block)
        end

        def merge_options(options)
          self.class.merge_options(common_options, options)
        end

        def self.merge_options(common_options, options)
          common_options.merge(options) do |key, oldVal, newVal|
            if key == :scope
              # 合并 common_options 和 options 中的 scope 选项
              Scope::Utils.and(oldVal, newVal)
            else
              # 关于 param、render 内部选项的合并问题暂不考虑
              newVal
            end
          end
        end
      end

      attr_reader :properties

      def initialize(options = {}, &)
        raise 'type 选项必须是 object' if !options[:type].nil? && options[:type] != 'object'

        @schema_cache = {} # 用于缓存已经生成的 schema，重复利用

        @properties = {} # 所有的属性已经生成
        @required = []
        @validations = {}

        options = options.merge(type: 'object')
        properties = options.delete(:properties)
        @options = options

        properties&.each do |name, property_options|
          if property_options.is_a?(Hash)
            property name, property_options
          elsif property_options.is_a?(BaseSchema)
            @properties[name.to_sym] = property_options
          else
            raise ArgumentError, "属性 #{name} 的类型不正确"
          end
        end

        instance_exec(&) if block_given?
      end

      def schema_name(schema_base_name = nil)
        if schema_base_name
          raise TypeError, "schema_base_name 必须是一个 String，当前是：#{schema_base_name.class}" unless schema_base_name.is_a?(String)
          @schema_name = schema_base_name
        else
          @schema_name
        end
      end

      def property(name, options = {}, &block)
        @properties[name.to_sym] = Properties.build_property(options, ->(options) { SchemaBuilderTool.build(options, &block) })
        # @properties[name.to_sym] = SchemaBuilderTool.build(options, &block)
      end

      alias expose property
      alias param property

      # 能且仅能 ObjectSchemaBuilder 内能使用 use 方法
      def use(proc)
        proc = proc.to_proc if proc.respond_to?(:to_proc)
        instance_exec(&proc)
      end

      def with_common_options(common_options, &block)
        WithCommonOptions.new(self, common_options, &block)
      end

      def scope(scope, options = {}, &)
        with_common_options(**options, scope: scope, &)
      end

      def params(options = {}, &block)
        with_common_options(**options, render: false, &block)
      end

      def render(options = {}, &block)
        with_common_options(**options, param: false, &block)
      end

      def merge(schema_builder)
        schema_builder = schema_builder.schema_builder if schema_builder.respond_to?(:schema_builder)

        @properties.merge!(schema_builder.properties)
      end

      def within(*properties)
        to_schema.properties.within(*properties)
      end
      alias_method :[], :within

      def to_schema(locked_options = {})
        locked_options = SchemaOptions::UserOptions::Filter.check(locked_options.compact)
        return @schema_cache[locked_options] if @schema_cache[locked_options]

        properties = @schema_name ? NamedProperties.new(@properties, @schema_name) : Properties.new(@properties)
        @schema_cache[locked_options] = ObjectSchema.new(properties: properties, options: @options, locked_options: locked_options)
      end

      def locked(options)
        Locked.new(self, **options)
      end
      include Locked::LockedMethodAlias

      private

        def apply_array_scope?(options, block)
          options[:type] == 'array' && (options[:items] || block)
        end

        def apply_object_scope?(options, block)
          (options[:type] == 'object' || block) && (options[:properties] || block)
        end
    end
  end
end