# frozen_string_literal: true

module Dain
  module SwaggerDocUtil
    class << self
      def generate(application)
        routes = application.routes
        routes += application.applications.map { |app| app.routes }.flatten

        paths = routes.group_by { |route| route.path }.map do |path, routes|
          # path 需要规范化
          path = path.gsub(/[:*](\w+)/, '{\1}')

          operations = routes.map do |route|
            [route.method.downcase.to_sym, generate_operation_object(route)]
          end.to_h
          [path, operations]
        end.to_h

        {
          openapi: '3.0.0',
          paths: paths
        }
      end

      def generate_operation_object(route)
        meta = route.meta
        operation_object = {}

        operation_object[:tags] = meta[:tags] if meta.key?(:tags)
        operation_object[:summary] = meta[:title] if meta.key?(:title)
        operation_object[:description] = meta[:description] if meta.key?(:description)

        if meta.key?(:params_schema)
          parameters = meta[:params_schema].generate_parameters_doc
          operation_object[:parameters] = parameters unless parameters.empty?

          schema = meta[:params_schema].to_schema_doc(stage: :param)
          if schema
            operation_object[:requestBody] = {
              content: {
                'application/json' => {
                  schema: schema
                }
              }
            }
          end
        end

        if meta.key?(:responses)
          operation_object[:responses] = meta[:responses].transform_values do |entity_scope|
            {
              content: {
                'application/json' => {
                  schema: entity_scope.to_schema_doc(stage: :render)
                }
              }
            }
          end
        end

        operation_object
      end
    end
  end
end
