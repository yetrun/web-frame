require 'spec_helper'
require 'json'
require 'grape-entity'

describe 'Meta::SwaggerDocUtil.generate' do
  subject { app.to_swagger_doc }

  let(:app) do
    app = Class.new(Meta::Application)
    app
  end

  it 'generates swagger documentation' do
    expect(subject).to include(openapi: '3.0.0')
  end
end
