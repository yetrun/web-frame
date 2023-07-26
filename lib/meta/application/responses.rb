# frozen_string_literal: true

module Meta
  class Responses
    extend Forwardable

    attr_reader :responses

    def initialize(responses = {})
      @responses = responses || {}
    end

    def_delegators :@responses, :[], :empty?, :length, :keys

    def to_swagger_doc(schemas, scope:)
      if responses.empty?
        { '200' => { description: '' } }
      else
        responses.transform_values do |schema|
          {
            description: '', # description 属性必须存在
            content: schema ? {
              'application/json' => {
                schema: schema.to_schema_doc(stage: :render, scope: scope, schemas: schemas)
              }
            } : nil
          }.compact
        end
      end
    end
  end
end
