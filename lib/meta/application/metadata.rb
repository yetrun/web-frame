# frozen_string_literal: true

require_relative 'parameters'
require_relative 'responses'

module Meta
  class Metadata
    module ExecutionMethods
      def parse_parameters(execution)
        parameters.filter(execution.request)
        # TODO: 未捕获 JsonSchema::ValidationErrors 异常
      end

      def parse_request_body(execution, discard_missing: false)
        method = execution.request.request_method.downcase.to_sym
        request_body.filter(
          execution.params(:raw),
          **Meta.config.json_schema_user_options,
          **Meta.config.json_schema_param_stage_user_options,
          **{ execution: execution, stage: :param, scope: @scope.concat([method]), discard_missing: discard_missing }.compact
        )
      rescue JsonSchema::ValidationErrors => e
        raise Errors::ParameterInvalid.new(e.errors)
      end

      def render_entity(execution, entity_schema, value, user_options)
        method = execution.request.request_method.downcase.to_sym
        entity_schema.filter(value,
          **Meta.config.json_schema_user_options,
          **Meta.config.json_schema_render_stage_user_options,
          **{ execution: execution, stage: :render, scope: @scope.concat([method]) }.compact,
          **user_options,
        )
      end

      def set_response(execution)
        set_status(execution)
        render_response_body(execution) if self.responses
      end

      private

      def set_status(execution)
        response_definitions = self.responses
        response = execution.response
        if response.status == 0
          response.status = (response_definitions&.length > 0) ? response_definitions.keys[0] : 200
        end
      end

      def render_response_body(execution)
        response_definitions = self[:responses]
        return if response_definitions.empty? # 未设定 status 宏时不需要执行 render_entity 方法

        # 查找 entity schema
        entity_schema = response_definitions[execution.response.status]
        return if entity_schema.nil?

        # 执行面向 schema 的渲染
        execution.render_entity(entity_schema)
      end
    end

    include ExecutionMethods

    attr_reader :title, :description, :tags, :parameters, :request_body, :responses, :scope

    def initialize(title: nil, description: nil, tags: [], parameters: {}, request_body: nil, responses: nil, scope: nil)
      @title = title
      @description = description
      @tags = tags
      @parameters = parameters.is_a?(Parameters) ? parameters : Parameters.new(parameters)
      @request_body = request_body
      @responses = responses.is_a?(Responses) ? responses : Responses.new(responses)
      @scope = scope
    end

    def [](key)
      send(key)
    end

    def generate_operation_doc(schemas, scope: [])
      operation_object = {}

      operation_object[:summary] = title if title
      operation_object[:tags] = tags unless tags.empty?
      operation_object[:description] = description if description

      operation_object[:parameters] = parameters.to_swagger_doc

      if request_body
        schema = request_body.to_schema_doc(stage: :param, scope: self.scope + scope, schemas: schemas)
        if schema || true
          operation_object[:requestBody] = {
            content: {
              'application/json' => {
                schema: schema
              }
            }
          }
        end
      end

      operation_object[:responses] = responses.to_swagger_doc(schemas, scope: self.scope + scope)

      operation_object.compact
    end

    class << self
      def new(meta = {})
        meta.is_a?(Metadata) ? meta : super(**meta)
      end
    end
  end
end
