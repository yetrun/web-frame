# frozen_string_literal: true

require_relative 'scopes'

module Entities
  class ObjectScopeBuilder
    def initialize(options = {}, &block)
      @properties = {}
      @options = options

      @required = []

      instance_exec(&block)
    end

    def property(name, options = {}, &block)
      name = name.to_sym

      # 规范化 options
      if options[:type] =~ /array<(\w+)>/
        options[:type] = $1
        options[:is_array] = true
      elsif options[:type] =~ /(\w+)\[\]/
        options[:type] = options[:type][0..-3]
        options[:is_array] = true
      end

      if options[:required]
        @required << name 
        options.delete(:required) unless options[:in] && options[:in] != :body
      end

      if options[:is_array]
        @properties[name] = ArrayScopeBuilder.new(options, &block).to_scope
      elsif block_given?
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
  end

  class ArrayScopeBuilder
    def initialize(options, &block)
      @options = options

      if block_given?
        @items  = ObjectScopeBuilder.new(&block).to_scope # TODO: options 怎么办？
      else
        options = options.dup
        options.delete(:is_array)
        options.delete(:description)
        @items = BaseScope.new(options)
      end
    end

    def to_scope
      ArrayScope.new(@items, @options)
    end
  end
end
