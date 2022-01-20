require 'spec_helper'
require_relative '../../lib/swagger_doc'
require 'json'
require 'grape-entity'

describe 'SwaggerDocUtil.generate' do

  subject do
    doc = SwaggerDocUtil.generate(app) 
    doc[:paths]['/user'][:get][:responses]['200'][:content]['application/json'][:schema]
  end
  
  let(:app) do
    app = Class.new(Application)

    the_arguments = arguments
    app.route('/user', :get)
      .exposures {
        expose(*the_arguments)
      }

    app
  end

  let(:entity_class) do
    Class.new(Grape::Entity) do
      expose :name, :age
    end
  end

  describe 'generating responses schema documentation' do
    context '.expose(:key, entity_class)' do
      let(:arguments) { [:user, entity_class] }

      it {
        is_expected.to eq(
          type: 'object',
          properties: {
            user: {
              type: 'object',
              properties: {
                name: {},
                age: {}
              }
            }
          }
        )
      }
    end

    context '.expose(:key)' do
      let(:arguments) { [:user] }

      it {
        is_expected.to eq(
          type: 'object',
          properties: {
            user: {}
          }
        )
      }
    end

    context '.expose(entity_class)' do
      let(:arguments) { [entity_class] }

      it {
        is_expected.to eq(
          type: 'object',
          properties: {
            name: {},
            age: {}
          }
        )
      }
    end

    context '.expose()' do
      let(:arguments) { [] }

      it {
        is_expected.to eq(
          type: 'object',
          properties: {}
        )
      }
    end
  end
end
