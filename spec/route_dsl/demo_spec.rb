# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/route_dsl/application_builder'

describe 'Route DSL' do
  include Rack::Test::Methods

  describe '一个带有所有基本要素的 DSL 实例' do
    def app
      article_entity = Class.new(Dain::Entities::Entity) do
        property :title
        property :content
      end

      Class.new(Dain::Application) do
        route '/article', :put do
          title '更新一篇新的文章'
          params do
            param :article, using: article_entity
          end
          status 200 do
            expose :article, using: article_entity
          end
          action do
            article = {
              :'title' => params[:article][:title].capitalize,
              :'content' => params[:article][:content].capitalize,
            }
            render('article' => article)
          end
        end
      end
    end

    specify do
      put '/article', JSON.generate('article' => { 'title' => 'title', 'content' => 'content' }), { 'CONTENT_TYPE' => 'application/json' }
      expect(JSON.parse(last_response.body)['article']).to eq('title' => 'Title', 'content' => 'Content')
    end
  end

  describe '嵌套路由' do
    def app
      Class.new(Dain::Application) do
        namespace '/nesting' do
          route '/foo', :get do
            action do
              response.body = ['foo']
            end
          end

          route '/bar', :get do
            action do
              response.body = ['bar']
            end
          end
        end
      end
    end

    specify do
      get '/nesting/foo'
      expect(last_response.body).to eq('foo')

      get '/nesting/bar'
      expect(last_response.body).to eq('bar')
    end
  end
end
