# frozen_string_literal: true

require 'spec_helper'
require 'json'
require 'grape-entity'

describe 'Meta::SwaggerDocUtil.generate' do
  describe 'generating response documentation' do
    context 'with Entities' do
      context 'with setting param to `false`' do
        subject do 
          Meta::SwaggerDocUtil.generate(app)[:paths]['/request'][:post][:responses][201][:content]['application/json'][:schema]
        end

        let(:app) do
          app = Class.new(Meta::Application)

          app.route('/request', :post)
            .status(201) {
              property :foo, type: 'string', param: false
              property :bar, type: 'string'
            }

          app
        end

        it '同时渲染 `bar`、`foo` 字段' do
          expect(subject[:properties].keys).to eq([:foo, :bar])
        end
      end
    end
  end
end
