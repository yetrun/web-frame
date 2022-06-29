# frozen_string_literal: true

# Note: 响应实体的生成与参数的一致，所以这里不再做深层次的测试了

require 'spec_helper'
require_relative '../../lib/swagger_doc'

describe 'Dain::SwaggerDocUtil.generate' do
  subject do
    doc = Dain::SwaggerDocUtil.generate(app)
    doc[:paths]['/user'][:get][:responses][200][:content]['application/json'][:schema]
  end

  def app
    app = Class.new(Dain::Application)

    app.route('/user', :get)
      .if_status(200) {
        expose :user, type: 'object' do
          expose :name, type: 'string'
          expose :age, type: 'integer'
        end
      }

    app
  end

  it {
    is_expected.to eq(
      type: 'object',
      properties: {
        user: {
          type: 'object',
          properties: {
            name: { type: 'string' },
            age: { type: 'integer' }
          }
        }
      }
    )
  }
end
