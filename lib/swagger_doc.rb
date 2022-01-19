module SwaggerDocUtil
  class << self
    def generate(application)
      routes = application.routes.routes
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
      operation_object[:requestBody] = {
        content: {
          'application/json' => {
            schema: generate_parameters_schema(route)
          }
        }
      }
      operation_object[:responses] = {
        '200' => {
          content: {
            'application/json' => {
              schema: {
                type: 'object',
                properties: route.exposures.map do |key, entity|
                  [key, generate_entity_schema(entity)]
                end.to_h
              }
            }
          }
        }
      } if route.respond_to?(:exposures)

      operation_object
    end

    def generate_parameters_schema(route)
      return route.respond_to?(:param_scope) ? route.param_scope.to_schema : {}
    end

    def generate_entity_schema(entity)
      {
        type: 'object',
        properties: entity.root_exposures.map { |exposure| [exposure.key, {}] }.to_h
      }
    end
  end
end
