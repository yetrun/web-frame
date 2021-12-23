require 'pry'
require "rack/test"
require 'json'
require_relative '../lib/application'

describe Application, '.param' do
  include Rack::Test::Methods

  before do
    @holder = []
  end

  describe '参数的过滤' do
    def app
      holder = @holder

      app = Class.new(Application)

      app.route('/users', :post)
        .param(:name)
        .param(:age)
        .do_any { 
          holder[0] = params 
        }

      app
    end

    it '未声明的参数被过滤出去' do
      post('/users', JSON.generate(name: 'Jim', age: 18, foo: 'bar'), { 'CONTENT_TYPE' => 'application/json' })

      expect(last_response).to be_ok

      expect(@holder[0]).to eq(name: 'Jim', age: 18)
    end
  end

  describe '参数的类型' do
    def app
      app = Class.new(Application)

      app.route('/users', :post)
        .param(:name, type: String)
        .param(:age, type: Integer)

      app
    end

    it '错误的参数类型将报错' do
      expect { 
        post('/users', JSON.generate(name: 'Jim', age: '18'), { 'CONTENT_TYPE' => 'application/json' })
      }.to raise_error(Errors::ParameterInvalid)
    end
  end

  describe '参数的 required' do
    def app
      app = Class.new(Application)

      app.route('/users', :post)
        .param(:name, required: true)
        .param(:age)

      app
    end

    it '不传递 required 的参数将报错' do
      expect { 
        post('/users', JSON.generate(age: 18), { 'CONTENT_TYPE' => 'application/json' })
      }.to raise_error(Errors::ParameterInvalid)
    end
  end

  describe '参数的默认值' do
    def app
      holder = @holder

      app = Class.new(Application)

      app.route('/users', :post)
        .param(:name)
        .param(:age, default: 18)
        .do_any { holder[0] = params }

      app
    end

    it '参数设置默认值' do
      post('/users', '{}', { 'CONTENT_TYPE' => 'application/json' })

      expect(@holder[0]).to eq(name: nil, age: 18)
    end
  end

  describe '参数在嵌套' do
    def app
      holder = @holder

      app = Class.new(Application)

      app.route('/users', :post)
        .param(:user) do
          param :name
          param :age
        end
        .do_any { holder[0] = params }

      app
    end

    it '传递嵌套参数' do
      post('/users', JSON.generate(user: { name: 'Jim', age: 18, bar: 'bar' }, foo: 'foo'), { 'CONTENT_TYPE' => 'application/json' })

      expect(@holder[0]).to eq(user: { name: 'Jim', age: 18 })
    end
  end
end
