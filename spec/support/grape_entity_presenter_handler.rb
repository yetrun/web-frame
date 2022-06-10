# frozen_string_literal: true

class GrapeEntityPresenterHandler
  class << self
    def handle?(klass)
      klass.is_a?(Class) && klass < Grape::Entity
    end

    def present(presenter, value)
      presenter.represent(value).as_json
    end

    def to_schema(presenter, other_options)
      schema = generate_entity_schema(presenter)
      schema[:description] = other_options[:description] if other_options[:description]
      schema
    end

    private

    def generate_entity_schema(entity_class, is_array = false)
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
  end
end
