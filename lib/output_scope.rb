# frozen_string_literal: true

class OutputScope
  def initialize(&block)
    @root_outputs = nil
    @outputs = {}

    instance_eval(&block) if block_given?
  end

  # 调用方式：
  # - output
  #
  # - output(UserEntity)
  # - output(UserEntity, full: true)
  #
  # - output(:user)
  # - output(:user, UserEntity)
  # - output(:user, UserEntity, full: true)
  # - output(:user, type: 'object')
  def output(*arguments, &block)
    values = Arguments.resolve_fn_output(arguments)

    key = values[:key]
    entity_class = values[:entity_class]
    options = values[:options] || {}

    if key.is_a?(Symbol)
      @outputs[key] = {
        block: block,
        entity_class: entity_class,
        options: options
      }
    else
      raise '不支持根 Exposure 的类型为数组' if options[:is_array]

      @root_outputs = {
        block: block,
        entity_class: entity_class,
        options: options
      }
    end
  end

  def generate_json(execution)
    root_hash = {}
    if @root_outputs
      root_hash = generate_with_block(execution, @root_outputs)
      raise 'Root exposure 的结果必须是一个 Hash' unless root_hash.is_a?(Hash)
    end

    exposures_hash = @outputs.transform_values do |exposure|
      generate_with_block(execution, exposure)
    end

    JSON.generate(root_hash.merge(exposures_hash))
  end

  def to_schema
    schema = {
      type: 'object',
      properties: {}
    }

    if @root_outputs && @root_outputs[:entity_class]
      schema = generate_entity_schema(@root_outputs[:entity_class], @root_outputs[:options][:is_array])
    end

    properties = @outputs.transform_values do |output|
      if output[:entity_class]
        output_schema = generate_entity_schema(output[:entity_class], output[:options][:is_array])
      else
        output_schema = {}
        output_schema[:type] = output[:options][:type] if output[:options][:type]
        output_schema = { type: 'array', items: output_schema } if output[:options][:is_array]

      end

      output_schema[:description] = output[:options][:description] if output[:options][:description]
      output_schema
    end
    schema[:properties].merge!(properties)

    schema
  end

  private

  def generate_with_block(execution, output)
    value = execution.instance_exec(&output[:block])
    value = output[:entity_class].represent(value, output[:options]) if output[:entity_class]
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
    def self.resolve_fn_output(arguments)
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
