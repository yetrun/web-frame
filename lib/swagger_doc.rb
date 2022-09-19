# frozen_string_literal: true

module Dain
  module SwaggerDocUtil
    class << self
      def generate(application)
        routes = get_paths_and_routes!(application)

        paths = routes.group_by { |path, route| path }.map { |path, routes| [path, routes.map { |item| item[1] }]}.map do |path, routes|
          operations = routes.map do |route|
            [route.method.downcase.to_sym, generate_operation_object(route)]
          end.to_h

          # path 需要规范化
          path = path.gsub(/[:*](\w+)/, '{\1}')
          [path, operations]
        end.to_h

        {
          openapi: '3.0.0',
          paths: paths
        }
      end

      # 生成单个路由的文档
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

      private

      # 获取所有路径和路由对象的映射关系，返回的形式是：
      #
      #     [
      #       ['/foo', route1],
      #       ['/foo', route2],
      #       ['/bar', route3],
      #       ['/bar', route4],
      #     ]
      #
      # 参数 path 是对应 application 的路径
      def get_paths_and_routes!(application, path = Path.new, store_routes = [])
        if (application.is_a?(Class) && application < Application) || application.is_a?(Application)
          (application.routes + application.applications).each do |app|
            get_paths_and_routes!(app, path, store_routes)
          end
        elsif application.is_a?(Route)
          route = application
          route_path = route.path == :all ? path.to_s : path.append(route.path).to_s
          store_routes << [route_path, route] unless route.method == :all
          route.children.each do |child|
            get_paths_and_routes!(child, route_path, store_routes)
          end
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
