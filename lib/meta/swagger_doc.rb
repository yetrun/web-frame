# frozen_string_literal: true

module Meta
  module SwaggerDocUtil
    class << self
      def generate(application, info: {}, servers: [])
        paths_and_routes = get_paths_and_routes!(application)
        return generate_from_paths_and_routes(paths_and_routes, info: info, servers: servers)
      end

      def generate_from_paths_and_routes(paths_and_routes, info: {}, servers: [])
        schemas = {}
        paths = paths_and_routes.group_by { |path, route| path }.map { |path, routes| [path, routes.map { |item| item[1] }]}.map do |path, routes|
          operations = routes.map do |route|
            [route.method.downcase.to_sym, generate_operation_object(route, schemas)]
          end.to_h

          # path 需要规范化
          path = path.gsub(/[:*](\w+)/, '{\1}')
          [path, operations]
        end.to_h

        doc = {
          openapi: '3.0.0',
          info: info,
          servers: servers,
          paths: paths
        }
        doc[:components] = { schemas: schemas } unless schemas.empty?
        doc
      end

      # 生成单个路由的文档
      def generate_operation_object(route, schemas)
        route.generate_operation_doc(schemas)
      end

      private

      # 获取所有路径和路由对象的映射关系，返回的形式是：
      #
      #     [
      #       ['/foo', route1],
      #       ['/foo', route2],
      #       ['/bar', route3],
      #       ['/bar', route4],
      #     ]
      def get_paths_and_routes!(application, prefix = '', store_routes = [])
        if (application.is_a?(Class) && application < Application) || application.is_a?(Application)
          prefix = Utils::Path.join(prefix, application.prefix)
          (application.routes + application.applications).each do |mod|
            get_paths_and_routes!(mod, prefix, store_routes)
          end
        elsif application.is_a?(Route)
          route = application
          route_path = route.path == :all ? prefix : Utils::Path.join(prefix, route.path)
          store_routes << [route_path, route] unless route.method == :all
        else
          raise "Param application must be a Application instance, Application module or a Route instance, but it got a `#{application}`"
        end

        store_routes
      end
    end

    class Path
      def initialize(parts = [])
        @parts = parts.freeze
      end

      def append(part)
        part = part[1..-1] if part.start_with?('/')
        parts = part.split('/')

        self.class.new(@parts + parts)
      end

      def to_s
        '/' + @parts.join('/')
      end

      def self.from_string(path)
        path = path[1..-1] if path.start_with?('/')
        parts = path.split('/')
        self.class.new(parts)
      end
    end
  end
end
