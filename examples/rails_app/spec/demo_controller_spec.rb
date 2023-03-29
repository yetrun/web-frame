require 'rails_helper'

RSpec.describe "DemoController", type: :request do
  describe "参数" do
    it "过滤参数到 params，原始参数存储到 raw_params" do
      post '/parse_params', params: { user: {} }, as: :json
      expect(response.status).to eq(200)

      response_body = JSON.parse(response.body)
      # params 被修改，同时保留 controller 和 action 参数
      expect(response_body['params']).to eq(
        'user' => { 'name' => 'Jim', 'age' => 18 },
        'controller' => 'demo',
        'action' => 'parse_params'
      )
      # 旧的 params 被存储到 raw_params 中
      expect(response_body['raw_params']).to include(
        'user' => {},
        'controller' => 'demo',
        'action' => 'parse_params'
      )
    end

    it "参数异常自动捕获" do
      post '/parse_params', params: {}, as: :json
      expect(response.status).to eq(400)
    end
  end

  describe '渲染' do
    it "默认值设定起作用" do
      post '/render_hash', params: { user: {} }, as: :json
      expect(response.status).to eq(200)

      response_body = JSON.parse(response.body)
      expect(response_body['user']).to eq('name' => 'Jim', 'age' => 18)
    end

    it "使用不同的块定义" do
      post '/render_hash', params: { user: {}, status: 201 }, as: :json
      expect(response.status).to eq(201)

      response_body = JSON.parse(response.body)
      expect(response_body['user']).to eq('name' => 'Jack', 'age' => 20)
    end

    describe 'render object' do
      it "render 一个对象" do
        post '/render_object'
        expect(response.status).to eq(200)

        response_body = JSON.parse(response.body)
        expect(response_body['user']).to eq('name' => 'Jim', 'age' => 18)
      end
    end

    context 'with execution:, stage:, scope:' do
      it "使用选项" do
        post '/render_with_options', params: { user: { a: 'a', b: 'b', c: 'c', d: 'd' }, status: 202 }, as: :json
        expect(response.status).to eq(200)

        response_body = JSON.parse(response.body)
        expect(response_body['user']).to eq('a' => 'aa', 'b' => 'b')
      end
    end
  end
end
