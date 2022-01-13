module SwaggerDocUtil
  class << self
    def generate(application)
      routes = application.routes.routes
      paths = routes.group_by { |route| route.path }.map do |path, routes|
        operations = routes.map do |route|
          [route.method.downcase.to_sym, {}]
        end.to_h
        [path, operations]
      end.to_h

      { 
        openapi: '3.0.0',
        paths: paths
      }
    end
  end
end
