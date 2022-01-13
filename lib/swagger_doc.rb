module SwaggerDocUtil
  class << self
    def generate(application)
      routes_doc = application.routes.routes.map do |route|
        "#{route.method} #{route.path}"
      end

      { 
        openapi: '3.0.0',
        routes: routes_doc
      }
    end
  end
end
