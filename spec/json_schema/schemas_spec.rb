require 'spec_helper'
require_relative '../../lib/entities/scope_builders'

describe 'schemas' do
  it 'required: 捕获未提供的参数' do
    builder = Entities::ObjectScopeBuilder.new do
      param :name, type: 'string'
      param :age, type: 'integer', default: 18

      required :name
    end
    schema = builder.to_scope

    expect {
      schema.filter({ 'age' => 18 }, '', nil, {})
    }.to raise_error(Errors::EntityInvalid) { |e|
      expect(e.errors['name']).to eq('未提供')
    }
  end
end
