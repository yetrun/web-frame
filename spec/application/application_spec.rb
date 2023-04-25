require 'spec_helper'

describe Meta::Application do
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
