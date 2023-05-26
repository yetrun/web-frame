require 'spec_helper'

describe Meta::Application do
  describe '参数体格式为 JSON' do
    def app
      Class.new(Meta::Application) do
        post '/no-params'

        post '/require-params' do
          params do
            param :p1
            param :p2
          end
          action do
            response.body = [JSON.generate(params)]
          end
        end
      end
    end

    it '对于未设置参数的接口，传递错误的请求体没有关系' do
      post '/no-params', "Hello, world!", { 'Content-Type' => 'text/plain' }
      expect(last_response.status).to eq 200
    end

    it '对于设置参数的接口，传递错误的请求体会报错' do
      expect {
        post '/require-params', "Hello, world!", { 'Content-Type' => 'text/plain' }
      }.to raise_error(Meta::Errors::UnsupportedContentType)
    end
  end

  describe '响应体格式为 JSON' do
    def app
      Class.new(Meta::Application) do
        get '/no-set-status' do
          action do
            response.body = ['Hello, world!']
          end
        end

        get '/set-status-but-no-set-entity' do
          status 204
          action do
            response.status = 204
          end
        end

        get '/set-status-and-set-entity' do
          status 200 do
            expose :foo
          end
          action do
            response.body = [JSON.generate('foo' => 'foo', 'bar' => 'bar')]
          end
        end
      end
    end

    it '对于未设置 status 的请求，不会设置响应体的格式为 application/json' do
      get '/no-set-status'
      expect(last_response.status).to eq 200
      expect(last_response.headers['Content-Type']).to be_nil
    end

    it '对于设置 status 的请求但是未设置响应实体的，不会设置响应体的格式为 application/json' do
      get '/set-status-but-no-set-entity'
      expect(last_response.status).to eq 204
      expect(last_response.headers['Content-Type']).to be_nil
    end

    it '对于设置 status 的请求，设置响应体的格式为 application/json' do
      get '/set-status-and-set-entity'
      expect(last_response.status).to eq 200
      expect(last_response.headers['Content-Type']).to eq 'application/json'
      expect(last_response.body).to eq '{"foo":"foo"}'
    end
  end
end
