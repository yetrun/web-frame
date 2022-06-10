# frozen_string_literal: true

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
        if apply_array_scope?(options, block)
          @properties[name] = ArraySchemaBuilder.new(options, &block).to_scope
        elsif apply_object_scope?(options, block)
          @properties[name] = ObjectSchemaBuilder.new(options, &block).to_scope # TODO: options 怎么办？
        else
          @properties[name] = BaseSchema.new(options, name)
        end
      elsif block.respond_to?(:to_scope)
        scope = block.to_scope
        if options[:type] == 'array'
          @properties[name] = ArraySchema.new(scope)
        else
          @properties[name] = ObjectSchema.new(scope.properties, scope.object_validations, options)
        end
      else
        raise "非法的参数。应传递代码块，或通过 using 选项传递 Proc、ObjectScope 或接受 `to_scope` 方法的对象。当前传递：#{block}"
      end
    end

    alias expose property
    alias param property

    # 能且仅能 ObjectSchemaBuilder 内能使用 use 方法
    def use(proc)
      proc = proc.to_proc if proc.respond_to?(:to_proc)
      instance_exec(&proc)
    end

    def to_scope
      ObjectSchema.new(@properties, @validations, @options)
    end

    private

    def apply_array_scope?(options, block)
      options[:type] == 'array' && (options[:items] || block)
    end

    def apply_object_scope?(options, block)
      (options[:type] == 'object' || block) && (options[:properties] || block)
    end
  end
end
