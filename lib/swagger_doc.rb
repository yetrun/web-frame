# frozen_string_literal: true

module SwaggerDocUtil
  class << self
    def generate(application)
      routes = application.routes.routes
      routes += application.applications.map { |app| app.routes.routes }.flatten

      paths = routes.group_by { |route| route.path }.map do |path, routes|
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
      operation_object = {}
      operation_object[:tags] = route.route_tags if route.respond_to?(:route_tags)
      operation_object[:requestBody] = {
        content: {
          'application/json' => {
            schema: route.param_scope.to_schema
          }
        }
      } if route.respond_to?(:param_scope)
      operation_object[:responses] = {
        '200' => {
          content: {
            'application/json' => {
              schema: route.exposure_scope.to_schema
            }
          }
        }
      } if route.respond_to?(:exposure_scope)

      operation_object
    end
  end
end
