require 'spec_helper'

describe Application do
  describe 'default status' do
    it 'sets status code' do
      response = Rack::Response.new
      expect(response.status).to eq 200
    end
  end

  describe '.set_status' do
    def app
      app = Class.new(Application)

      app.route('/status', :get)
        .set_status { 201 }

      app
    end

    it 'sets status code' do
      get '/status'

      expect(last_response.status).to eq 201
    end
  end

  describe '.if_status' do
    def app
      app = Class.new(Application)

      app.route('/status', :get)
        .do_any {
          response.status = 201
        }
        .if_status(200) {
          expose :status, value: proc { 'ok' }
        }
        .if_status(201) {
          expose :status, value: proc { 'created' }
        }
        .if_status(202) {
          expose :status, value: proc { 'accepted' }
        }

      app
    end

    it 'filters status' do
      get '/status'

      expect(last_response.status).to eq 201
      expect(JSON.parse(last_response.body)).to eq('status' => 'created')
    end
  end

  describe 'Execution#render' do
    def app
      app = Class.new(Application)
      app.route('/article', :get)
        .do_any {
          present({ article: { title: 'Title', content: 'Content', other: 'Other' }}, scope: 'other')
        }
        .if_status(200) {
          expose :article, type: 'object' do
            expose :title
            expose :content, scope: ['full', 'return']
            expose :other, scope: ['other', 'return']
          end
        }
      app
    end

    it '过滤掉 scope 声明不匹配的属性' do
      get '/article'

      expect(JSON.parse(last_response.body)).to eq('article' => { 'title' => 'Title', 'other' => 'Other' })
    end
  end
end
