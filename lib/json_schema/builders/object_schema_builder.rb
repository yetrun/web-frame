# frozen_string_literal: true

module Dain
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

      def property(name, options = {}, &block)
        name = name.to_sym
        options = options.dup

        # 能且仅能 ObjectSchemaBuilder 内能使用 using 选项
        block = options[:using] unless block_given?
        if block.nil? || block.is_a?(Proc)
          @properties[name] = SchemaBuilderTool.build(options, &block)
        elsif block.respond_to?(:to_schema)
          scope = block.to_schema
          if options[:type] == 'array'
            @properties[name] = ArraySchema.new(scope, options)
          else
            # TODO: 这里每次都要重新生成一个 ObjectSchema，不知是为什么。这样导致一个问题，每次 ObjectSchema 新增选项时，别忘了在这里把选项传递过去。
            @properties[name] = ObjectSchema.new(
              properties: scope.properties,
              object_validations: scope.object_validations,
              options: options,
              locked_options: scope.locked_options,
              schema_names: scope.schema_names
            )
          end
        else
          raise "非法的参数。应传递代码块，或通过 using 选项传递 Proc、ObjectScope 或接受 `to_schema` 方法的对象。当前传递：#{block}"
        end
      end

      alias expose property
      alias param property

      # 能且仅能 ObjectSchemaBuilder 内能使用 use 方法
      def use(proc)
        proc = proc.to_proc if proc.respond_to?(:to_proc)
        instance_exec(&proc)
      end

      def to_schema(locked_options = nil, schema_name = nil)
        ObjectSchema.new(properties: @properties, object_validations: @validations, options: @options, locked_options: locked_options, schema_names: schema_name)
      end

      # TODO: 设置 lock_scope 后，生成文档时属性依然没有过滤
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

        def to_schema
          builder.to_schema(locked_options)
        end
      end
    end
  end
end
