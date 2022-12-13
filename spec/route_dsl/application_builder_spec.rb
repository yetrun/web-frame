# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/route_dsl/application_builder'
require_relative '../../lib/swagger_doc'

describe 'Application Builder' do
  include Rack::Test::Methods

  describe '在 Application 层定义 params 的效果' do
    def app
      Class.new(Dain::Application) do
        namespace '/foo' do
          params do
            param :foo
          end

          before do
            @foo_in_namespace = params[:foo]
          rescue
            @foo_in_namespace = '无法访问'
          end

          post '/bar' do
            params do
              param :bar
            end
            action do
              response.body = [{
                foo_in_namespace: @foo_in_namespace,
                foo_in_route: params[:foo],
                bar_in_route: params[:bar]
              }.to_json]
            end
          end
        end
      end
    end

    it '检查接口调用的效果' do
      post '/foo/bar', JSON.generate(foo: 'foo', bar: 'bar'), { 'CONTENT_TYPE' => 'application/json' }
      expect(JSON.parse(last_response.body)).to eq({
        'foo_in_namespace' => nil,
        'foo_in_route' => nil,
        'bar_in_route' => 'bar'
      })
    end

    it '检查文档生成的效果' do
      doc = app.to_swagger_doc
      schema = doc[:paths]['/foo/bar'][:post][:requestBody][:content]['application/json'][:schema]
      expect(schema).to eq({
        type: 'object',
        properties: {
          bar: {}
        }
      })
    end
  end
end
