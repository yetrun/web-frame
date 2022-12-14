# frozen_string_literal: true

module Dain
  class Meta
    attr_reader :title, :description, :tags, :parameters, :request_body, :responses

    def initialize(title: nil, description: nil, tags: [], parameters: {}, request_body: nil, responses: {})
      @title = title
      @description = description
      @tags = tags
      @parameters = parameters
      @request_body = request_body
      @responses = responses
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
        property_options = options[:schema].param_options
        {
          name: name,
          in: options[:in],
          type: property_options[:type],
          required: property_options[:required] || false,
          description: property_options[:description] || ''
        }
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
          content: {
            'application/json' => {
              schema: schema.to_schema_doc(stage: :render, schemas: schemas)
            }
          }
        }
      end unless responses.empty?

      operation_object
    end

    def self.new(meta = {})
      meta.is_a?(Meta) ? meta : super(**meta)
    end
  end
end
