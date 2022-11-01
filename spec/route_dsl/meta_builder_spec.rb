# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/route_dsl/application_builder'
require_relative '../../lib/swagger_doc'

describe 'Meta Builder' do
  include Rack::Test::Methods

  describe 'params & status' do
    context '遇到 `required: true` 时' do
      def app
        entity = Class.new(Dain::Entities::Entity) do
          expose :foo
          expose :bar, required: true
        end

        Class.new(Dain::Application) do
          route '/request', :post do
            params do
              param :nested, using: entity
            end
            action do
              params(:discard_missing)
            end
          end
        end
      end

      it '调用 `params(:discard_missing)` 时不报错' do
        expect {
          post '/request', { 'nested' => { 'foo' => 'foo' } }.to_json, { 'CONTENT_TYPE' => 'application/json'}
        }.not_to raise_error
      end
    end

    describe 'render: false' do
      def app
        entity = Class.new(Dain::Entities::Entity) do
          expose :foo
          expose :bar, render: false
        end

        Class.new(Dain::Application) do
          route '/request', :post do
            status 200 do
              expose :nested, using: entity
            end
            action do
              render(:'nested', { 'foo' => 'foo', 'bar' => 'bar' })
            end
          end
        end
      end

      it '成功过滤 render 选项为 false 的属性' do
        post '/request'
        expect(JSON.parse(last_response.body)['nested'].keys).to eq(['foo'])
      end
    end
  end
end
