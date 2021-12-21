require 'json'
require 'rack'
require 'rack/test'
require_relative '../lib/application'

describe Execution, '#request' do
  include Rack::Test::Methods

  def app
    @holder = []
    holder = @holder

    app = Class.new(Application)

    app.route('/users', :get)
      .do_any { holder[0] = request; }

    app.route('/users', :post)
      .do_any { holder[0] = request; }

    app
  end

  it '得到 Rack::Request 对象' do
    get '/users'
    expect(last_response).to be_ok

    req = @holder[0]

    # 调用 Rack::Request 的方法
    expect(req.get?).to be true
  end


  it '获取 query string 中的 params' do
    get '/users?name=Jim&age=18'
    expect(last_response).to be_ok

    req = @holder[0]

    expect(req.params).to eq('name' => 'Jim', 'age' => '18')
  end

  it '无法自动获取 request body 中的 params' do
    post('/users', JSON.generate(name: 'Jim', age: 18), { 'CONTENT_TYPE' => 'application/json' })
    expect(last_response).to be_ok

    req = @holder[0]

    # 下面的行为并不是默认的行为，而是框架将其搞定的
    expect(req.params).to eq('name' => 'Jim', 'age' => 18)
  end

  it '修改 param' do
    post('/users', '{}', { 'CONTENT_TYPE' => 'application/json' })
    expect(last_response).to be_ok

    req = @holder[0]

    req.update_param('name', 'Jim')
    req.update_param('age', 18)
    expect(req.params).to eq('name' => 'Jim', 'age' => 18)
  end
end
