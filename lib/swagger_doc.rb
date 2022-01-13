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
      {
        requestBody: {
          content: {
            'application/json' => {
              schema: generate_parameters_schema(route)
            }
          }
        }
      }
    end

    def generate_parameters_schema(route)
      return route.respond_to?(:param_scope) ? route.param_scope.to_schema : {}
    end
  end
end
