require_relative '../entity'
require_relative '../route'
require 'json'

module Dain
  class Route
    class Builder
      def initialize(path = :all, method = :all)
        @path = path || :all
        @method = method || :all

        @meta = {}
        @children = []
        @blocks = []
      end

      def build
        children = @children.map { |builder| builder.build }
        Route.new(
          path: @path,
          method: @method,
          meta: @meta,
          blocks: @blocks,
          children: children
        )
      end

      # 定义子路由
      # TODO: 使用构建器
      def method(method)
        route = Route::Builder.new(nil, method)
        @children << route

        route
      end

      def nesting(&block)
        instance_eval(&block)

        nil
      end

      def do_any(&block)
        @blocks << block

        self
      end

      def params(options = {}, &block)
        params_schema = JsonSchema::BaseSchemaBuilder.build(options, &block)

        @meta[:params_schema] = params_schema

        do_any {
          request_body = request.body.read
          json = request_body.empty? ? {} : JSON.parse(request_body)
          json.merge!(request.params) if json.is_a?(Hash) # TODO: 如果参数模式不是对象，就无法合并 query 和 path 里的参数

          begin
            params = params_schema.filter(json, stage: :param)
          rescue JsonSchema::ValidationErrors => e
            raise Errors::ParameterInvalid.new(e.errors)
          end

          request.body.rewind

          define_singleton_method(:params) { params }
        }
      end

      def resource(&block)
        do_any {
          resource = instance_exec(&block)

          raise Errors::NotFound if resource.nil?

          # 为 execution 添加一个 resource 方法
          define_singleton_method(:resource) { resource }
        }
      end

      def authorize(&block)
        do_any {
          permitted = instance_eval(&block)
          raise Errors::NotAuthorized unless permitted
        }
      end

      # TODO: 如何定义数组和标量响应值
      def if_status(code, &block)
        entity_schema = JsonSchema::BaseSchemaBuilder.build(&block).to_schema

        @meta[:responses] = @meta[:responses] || {}
        @meta[:responses][code] = entity_schema

        do_any {
          next unless response.status == code

          # 首先获取 JSON 响应值
          if @render
            hash = @render[:value]
            options = @render[:options]
          else
            response_body = response.body ? response.body[0] : nil
            hash = response_body ? JSON.parse(response_body) : {}
            options = {}
          end

          # scope_filter = options[:scope] ? options[:scope] : []
          # scope_filter = [scope_filter] unless scope_filter.is_a?(Array)
          # scope_filter << 'return' unless scope_filter.include?('return')
          # options[:scope] = scope_filter

          begin
            new_hash = entity_schema.filter(hash, **options, execution: self, stage: :render)
          rescue JsonSchema::ValidationErrors => e
            raise Errors::RenderingInvalid.new(e.errors)
          end
          response.body = [JSON.generate(new_hash)]
        }
      end

      def set_status(&block)
        do_any {
          response.status = instance_exec(&block)
        }
      end

      def tags(names)
        @meta[:tags] = names

        self
      end

      def title(title)
        @meta[:title] = title

        self
      end

      def description(description)
        @meta[:description] = description

        self
      end
    end
  end
end
