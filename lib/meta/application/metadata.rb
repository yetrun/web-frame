# frozen_string_literal: true

module Meta
  class Metadata
    attr_reader :title, :description, :tags, :parameters, :request_body, :responses

    def initialize(title: nil, description: nil, tags: [], parameters: {}, request_body: nil, responses: nil)
      @title = title
      @description = description
      @tags = tags
      @parameters = parameters
      @request_body = request_body
      @responses = responses || { 204 => nil }
    end

    def [](key)
      send(key)
    end

    def generate_operation_doc(schemas)
      operation_object = {}

      operation_object[:summary] = title if title
      operation_object[:tags] = tags unless tags.empty?
      operation_object[:description] = description if description

      operation_object[:parameters] = parameters.map do |name, options|
        property_options = options[:schema].options
        {
          name: name,
          in: options[:in],
          required: property_options[:required] || nil,
          description: property_options[:description] || '',
          schema: {
            type: property_options[:type]
          }
        }.compact
      end unless parameters.empty?

      if request_body
        schema = request_body.to_schema_doc(stage: :param, schemas: schemas)
        if schema || true
          operation_object[:requestBody] = {
            content: {
              'application/json' => {
                schema: schema
              }
            }
          }
        end
      end

      operation_object[:responses] = responses.transform_values do |schema|
        {
          description: '', # description 属性必须存在
          content: schema ? {
            'application/json' => {
              schema: schema.to_schema_doc(stage: :render, schemas: schemas)
            }
          } : nil
        }.compact
      end unless responses.empty?

      operation_object
    end

    def self.new(meta = {})
      meta.is_a?(Metadata) ? meta : super(**meta)
    end
  end
end
