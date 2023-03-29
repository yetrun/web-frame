require 'rails_helper'

RSpec.describe "SwaggerController", type: :request do
  describe '生成 Swagger 文档' do
    it "生成文档" do
      get '/swagger_doc'
      expect(response.status).to eq(200)

      response_body = JSON.parse(response.body)
      expect(response_body['paths']).not_to be_empty
    end
  end
end
