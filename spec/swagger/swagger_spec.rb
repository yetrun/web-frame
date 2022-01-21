require 'spec_helper'
require_relative '../../lib/swagger_doc'
require 'json'
require 'grape-entity'

describe 'SwaggerDocUtil.generate' do
  subject { SwaggerDocUtil.generate(app) }

  let(:app) do
    app = Class.new(Application)
    app
  end

  it 'generates swagger documentation' do
    expect(subject).to include(openapi: '3.0.0')
  end
end
