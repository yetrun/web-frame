require 'spec_helper'
require_relative '../../lib/swagger_doc'
require 'json'
require 'grape-entity'

describe 'Dain::SwaggerDocUtil.generate' do
  subject { app.to_swagger_doc }

  let(:app) do
    app = Class.new(Dain::Application)
    app
  end

  it 'generates swagger documentation' do
    expect(subject).to include(openapi: '3.0.0')
  end
end
