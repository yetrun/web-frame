require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "正常创建用户" do
    post '/users', params: { user: {} }, as: :json
    assert_response :success

    response_body = JSON.parse(response.body)
    # params 被修改，同时保留 controller 和 action 参数
    assert_equal({
                   'user' => { 'name' => 'Jim', 'age' => 18 },
                   'controller' => 'users',
                   'action' => 'create'
                 }, response_body['params'])
    # 旧的 params 被存储到 raw_params 中
    assert_equal({
                   'user' => {},
                   'controller' => 'users',
                   'action' => 'create'
                 }, response_body['raw_params'])
  end

  test "user 参数未传递" do
    post '/users'
    assert_response :bad_request
  end
end
