
# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/json_schema/schemas'
require_relative '../../lib/entity'

describe 'Schema Builders' do
  it '属于数组的属性要保留' do
    schema = Dain::JsonSchema::BaseSchemaBuilder.build do
      property :array_value, type: 'array', using: Class.new(Dain::Entities::Entity), value: proc { |board| [] }
    end.to_schema

    array_schema = schema.properties[:array_value]
    expect(array_schema.items.is_a?(Dain::JsonSchema::ObjectSchema)).to be true
    expect(array_schema.render_options.include?(:value)).to be true
  end
end
