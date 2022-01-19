require 'spec_helper'

describe HashParamScope do
  describe 'to_schema' do
    subject do
      HashParamScope.new do
        param :name
        param :age
      end
    end

    it 'generates schema' do
      expect(subject.to_schema).to eq(
        type: 'object',
        properties: {
          name: {},
          age: {}
        }
      )
    end
  end
end
