require 'spec_helper'

describe 'Route DSL' do
  include Rack::Test::Methods

  def app
    article_entity = Class.new(Dain::Entities::Entity) do
      property :title
      property :content
    end

    builder = Dain::ApplicationBuilder.new do
      route '/article', :put do
        title '更新一篇新的文章'
        params do
          param :article, using: article_entity
        end
        status(200) do
          expose :article, using: article_entity
        end
        action do
          article = {
            'title' => params[:article][:title].capitalize,
            'content' => params[:article][:content].capitalize,
          }
          render :article, article
        end
      end
    end

    builder.build
  end

  it do
    put '/article', JSON.generate('title' => 'title', 'content' => 'content'), { 'CONTENT_TYPE' => 'application/json' }
    expect(JSON.parse(last_response.body)['article']).to eq('title' => 'Title', 'content' => 'Content')
  end
end
