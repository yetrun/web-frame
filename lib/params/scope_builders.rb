# frozen_string_literal: true

require_relative 'scopes'

module Params
  class ObjectScopeBuilder
    def initialize(&block)
      @properties = {}
      @required = []

      instance_exec(&block)
    end

    def param(name, options = {}, &block)
      name = name.to_sym

      # 规范化 options
      if options[:type] =~ /array<(\w+)>/
        options[:type] = $1
        options[:is_array] = true
      elsif options[:type] =~ /(\w+)\[\]/
        options[:type] = options[:type][0..-3]
        options[:is_array] = true
      end

      @required << name if options.delete(:required)

      if options[:is_array]
        @properties[name] = ArrayScopeBuilder.new(options, &block).to_scope
      elsif block_given?
        @properties[name] = ObjectScopeBuilder.new(&block).to_scope # TODO: options 怎么办？
      else
        @properties[name] = PrimitiveScope.new(options)
      end
    end

    def required(*names)
      @required += names
    end

    def to_scope
      properties = @properties
      validations = { required: @required }

      ObjectScope.new(properties, validations)
    end
  end

  class ArrayScopeBuilder
    def initialize(options, &block)
      if block_given?
        @items  = ObjectScopeBuilder.new(&block).to_scope # TODO: options 怎么办？
      else
        @items = PrimitiveScope.new(options)
      end
    end

    def to_scope
      ArrayScope.new(@items)
    end
  end
end
