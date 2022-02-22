# frozen_string_literal: true

require_relative 'scopes'

# 我们仅把具有内部结构的元素视为 ArrayScope 或 ObjectScope，哪怕它们的 type 是 object 或 array.
module Entities
  class ObjectScopeBuilder
    def initialize(options = {}, &block)
      @properties = {}
      @required = []

      options = options.dup
      properties = options.delete(:properties)
      @options = options

      if properties
        properties.each do |name, property_options|
          property name, property_options
        end
      end

      instance_exec(&block) if block_given?
    end

    def property(name, options = {}, &block)
      name = name.to_sym
      options = options.dup

      # Note: 暂时停用 integer[]、is_array 等写法
      # 规范化 options
      # if options[:type] =~ /array<(\w+)>/
      #   options[:type] = $1
      #   options[:is_array] = true
      # elsif options[:type] =~ /(\w+)\[\]/
      #   options[:type] = options[:type][0..-3]
      #   options[:is_array] = true
      # end

      if options[:required]
        @required << name
        options.delete(:required) unless options[:in] && options[:in] != :body
      end

      if array_property?(options, block)
        @properties[name] = ArrayScopeBuilder.new(options, &block).to_scope
      elsif object_property?(options, block)
        @properties[name] = ObjectScopeBuilder.new(options, &block).to_scope # TODO: options 怎么办？
      else
        @properties[name] = BaseScope.new(options, name)
      end
    end

    alias :expose :property
    alias :param :property

    def required(*names)
      @required += names
    end

    def to_scope
      properties = @properties
      validations = { required: @required }

      ObjectScope.new(properties, validations, @options)
    end

    def array_property?(options, block)
      options[:type] == 'array' && (options[:items] || block)
    end

    def object_property?(options, block)
      (options[:type] == 'object' || block) && (options[:properties] || block)
    end
  end

  class ArrayScopeBuilder
    def initialize(options, &block)
      options = options.dup
      @options = options

      # TODO: 使用 BaseBuilder 如果没有 items
      items_options = options.delete(:items) || {}
      if object_property?(items_options, block)
        @items = ObjectScopeBuilder.new(items_options, &block).to_scope # TODO: options 怎么办？
      else
        @items = BaseScope.new(items_options)
      end
    end

    def to_scope
      ArrayScope.new(@items, @options)
    end

    def object_property?(options, block)
      (options && options[:properties] != nil) || block != nil
    end
  end
end
