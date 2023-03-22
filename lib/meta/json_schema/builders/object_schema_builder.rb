# frozen_string_literal: true

require_relative '../schemas/properties'

module Meta
  module JsonSchema
    class ObjectSchemaBuilder
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

      def lock(key, value)
        locked(key => value)
      end

      def locked(options)
        Locked.new(self, options)
      end

      private

      def apply_array_scope?(options, block)
        options[:type] == 'array' && (options[:items] || block)
      end

      def apply_object_scope?(options, block)
        (options[:type] == 'object' || block) && (options[:properties] || block)
      end

      def method_missing(method, *args)
        if method =~ /^lock_(\w+)$/
          key = Regexp.last_match(1)
          lock(key.to_sym, *args)
        else
          super
        end
      end

      class Locked
        attr_reader :builder, :locked_options

        def initialize(builder, locked_options)
          @builder = builder
          @locked_options = locked_options
        end

        # 当调用 Entity.locked 方法后，生成 schema 的方法会掉到这里面来。
        # 在生成 schema 时，locked_options 会覆盖；当生成 schema 文档时，由于缺失 schema_name 的
        # 信息，故而 schema_name 相关的影响就消失不见了。
        def to_schema
          builder.to_schema(locked_options)
        end
      end
    end
  end
end
