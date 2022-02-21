# frozen_string_literal: true

# 也许已经被废弃

class EntityScope
  def initialize(&block)
    @root_entity = nil
    @entitys = {}

    instance_eval(&block) if block_given?
  end

  # 调用方式：
  # - entity
  #
  # - entity(UserEntity)
  # - entity(UserEntity, full: true)
  #
  # - entity(:user)
  # - entity(:user, UserEntity)
  # - entity(:user, UserEntity, full: true)
  # - entity(:user, type: 'object')
  def entity(*arguments, &block)
    values = Arguments.resolve_fn_entity(arguments)

    key = values[:key]
    entity_class = values[:entity_class]
    options = values[:options] || {}

    if key.is_a?(Symbol)
      @entitys[key] = {
        block: block,
        entity_class: entity_class,
        options: options
      }
    else
      raise '不支持根 Exposure 的类型为数组' if options[:is_array]

      @root_entity = {
        block: block,
        entity_class: entity_class,
        options: options
      }
    end
  end

  def generate_json(execution)
    root_hash = {}
    if @root_entity
      root_hash = generate_with_block(execution, @root_entity)
      raise 'Root exposure 的结果必须是一个 Hash' unless root_hash.is_a?(Hash)
    end

    exposures_hash = @entitys.transform_values do |exposure|
      generate_with_block(execution, exposure)
    end

    JSON.generate(root_hash.merge(exposures_hash))
  end

  def to_schema
    schema = {
      type: 'object',
      properties: {}
    }

    if @root_entity && @root_entity[:entity_class]
      schema = generate_entity_schema(@root_entity[:entity_class], @root_entity[:options][:is_array])
    end

    properties = @entitys.transform_values do |entity|
      if entity[:entity_class]
        entity_schema = generate_entity_schema(entity[:entity_class], entity[:options][:is_array])
      else
        entity_schema = {}
        entity_schema[:type] = entity[:options][:type] if entity[:options][:type]
        entity_schema = { type: 'array', items: entity_schema } if entity[:options][:is_array]

      end

      entity_schema[:description] = entity[:options][:description] if entity[:options][:description]
      entity_schema
    end
    schema[:properties].merge!(properties)

    schema
  end

  private

  def generate_with_block(execution, entity)
    value = execution.instance_exec(&entity[:block])
    value = entity[:entity_class].represent(value, entity[:options]) if entity[:entity_class]
    value = value.as_json if value.respond_to?(:as_json)

    value
  end

  def generate_entity_schema(entity_class, is_array)
    properties = entity_class.root_exposures.map { |exposure|
      documentation = exposure.documentation || {}

      if exposure.respond_to?(:using_class_name)
        schema = generate_entity_schema(
          exposure.using_class_name,
          exposure.documentation && exposure.documentation[:is_array]
        )
      else
        schema = {}
        schema[:type] = documentation[:type] if documentation[:type]
      end

      schema[:description] = documentation[:description] if documentation[:description]

      [exposure.key, schema]
    }.to_h

    schema = { type: 'object', properties: properties }
    schema = { type: 'array', items: schema } if is_array

    schema
  end

  module Arguments
    def self.resolve_fn_entity(arguments)
      value_matchers = {
        key: ->(value) { value.is_a?(Symbol) },
        entity_class: ->(value) { value.is_a?(Class) && value < Grape::Entity },
        options: ->(value) { value.is_a?(Hash) }
      }

      value_matchers.transform_values do |matcher|
        next nil if arguments.empty?
        next nil if arguments[0].nil?
        next arguments.shift if matcher.call(arguments[0])

        nil
      end
    end
  end
end
