module GrapeEntityHelper
  def self.generate_entity_schema(entity_class, is_array = false)
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
