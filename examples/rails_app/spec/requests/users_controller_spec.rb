require 'rails_helper'

RSpec.describe "UsersController", type: :request do
  describe "创建用户" do
    it "正常创建用户" do
      post '/users', params: { user: {} }, as: :json
      expect(response.status).to eq(200)

      response_body = JSON.parse(response.body)
      # params 被修改，同时保留 controller 和 action 参数
      expect(response_body['params']).to eq(
        'user' => { 'name' => 'Jim', 'age' => 18 },
        'controller' => 'users',
        'action' => 'create'
      )
      # 旧的 params 被存储到 raw_params 中
      expect(response_body['raw_params']).to eq(
        'user' => {},
        'controller' => 'users',
        'action' => 'create'
      )
    end

    it "user 参数未传递" do
      post '/users'
      assert_response :bad_request
    end
  end

  describe '更新用户' do
    it "默认值设定起作用" do
      put '/user', params: { user: {} }, as: :json
      assert_response :success
      expect(response.status).to eq(200)

      response_body = JSON.parse(response.body)
      expect(response_body['user']).to eq('name' => 'Jim', 'age' => 18)
    end
  end
end
