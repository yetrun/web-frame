# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/entities/scope_builders'
require_relative '../../../lib/json_schema/schemas'

describe JsonSchema::ObjectValidators do
  describe '添加自定义验证' do
    before do
      JsonSchema::ObjectValidators[:validation_one] = proc {
        raise JsonSchema::ValidationErrors.new('x' => 'wrong one', 'y' => 'wrong one')
      }
      JsonSchema::ObjectValidators[:validation_two] = proc {
        raise JsonSchema::ValidationErrors.new('y' => 'wrong two', 'z' => 'wrong two')
      }
    end

    after do
      JsonSchema::ObjectValidators.delete(:validation_one)
      JsonSchema::ObjectValidators.delete(:validation_two)
    end

    it '检验 ObjectValidators' do
      builder = Entities::ObjectScopeBuilder.new do
        property :x
        property :y
        property :z

        validates :validation_one
        validates :validation_two
      end
      schema = builder.to_scope

      expect {
        schema.filter({ 'x' => -1, 'y' => -3, 'z' => -5 })
      }.to raise_error(JsonSchema::ValidationErrors) do |e|
        expect(e.errors).to eq(
          'x' => 'wrong one',
          'y' => 'wrong one',
          'z' => 'wrong two'
        )
      end
    end
  end
end
