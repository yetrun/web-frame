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
          remove_instance_variable(:@_raw_params) if instance_variable_defined?(:@_raw_params)
          remove_instance_variable(:@_modified_params) if instance_variable_defined?(:@_modified_params)
          remove_instance_variable(:@_replaced_params) if instance_variable_defined?(:@_replaced_params)

          define_singleton_method(:parse_raw_params) do
            request_body = request.body.read
            json = request_body.empty? ? {} : JSON.parse(request_body)
            json.merge!(request.params) if json.is_a?(Hash) # TODO: 如果参数模式不是对象，就无法合并 query 和 path 里的参数

            request.body.rewind
            json
          end

          define_singleton_method(:parse_modified_params) do
            begin
              params_schema.filter(params(:raw), stage: :param, discard_missing: true)
            rescue JsonSchema::ValidationErrors => e
              raise Errors::ParameterInvalid.new(e.errors)
            end
          end

          define_singleton_method(:parse_replaced_params) do
            begin
              params_schema.filter(params(:raw), stage: :param)
            rescue JsonSchema::ValidationErrors => e
              raise Errors::ParameterInvalid.new(e.errors)
            end
          end

          define_singleton_method(:params) do |mode = nil|
            case mode
            when :raw
              @_raw_params || @_raw_params = parse_raw_params.freeze
            when :discard_missing
              @_modified_params || @_modified_params = parse_modified_params.freeze
            else
              @_replaced_params || @_replaced_params = parse_replaced_params.freeze
            end
          end

          params # 先激活一下
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

      def if_status(code, *other_codes, &block)
        codes = [code, *other_codes]

        entity_schema = JsonSchema::BaseSchemaBuilder.build(&block).to_schema

        @meta[:responses] = @meta[:responses] || {}
        codes.each { |code| @meta[:responses][code] = entity_schema }

        do_any {
          next unless codes.include?(response.status)

          # 首先获取 JSON 响应值
          renders = @renders || {}

          if renders.key?(:__root__) || renders.empty?
            # 从 root 角度获取
            if renders[:__root__]
              hash = renders[:__root__][:value]
              options = renders[:__root__][:options]
            else
              response_body = response.body ? response.body[0] : nil
              hash = response_body ? JSON.parse(response_body) : {}
              options = {}
            end

            begin
              new_hash = entity_schema.filter(hash, **options, execution: self, stage: :render)
            rescue JsonSchema::ValidationErrors => e
              raise Errors::RenderingInvalid.new(e.errors)
            end
            response.body = [JSON.generate(new_hash)]
          else
            # 渲染多键值结点
            new_hash = renders.map do |key, render_content|
              schema = entity_schema.properties[key]
              raise Errors::RenderingError, "渲染的键名 `#{key}` 不存在，请检查实体定义以确认是否有拼写错误" if schema.nil?

              [key, schema.filter(render_content[:value], render_content[:options])]
            end.to_h
            response.body = [JSON.generate(new_hash)]
          end
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
