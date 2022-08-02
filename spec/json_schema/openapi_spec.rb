# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/json_schema/schemas'

describe 'openapi' do
  it '生成对象 Schema 的文档' do
    schema = Dain::JsonSchema::BaseSchemaBuilder.build do
      param :user, description: '用户' do
        param :name
        param :age
      end
    end.to_schema

    expect(schema.to_schema_doc(stage: :param)).to eq(
      type: 'object',
      properties: {
        user: {
          type: 'object',
          description: '用户',
          properties: {
            name: {},
            age: {}
          }
        }
      }
    )
  end
end
