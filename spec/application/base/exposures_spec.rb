require 'spec_helper'
require 'json'

describe Application, '.exposures' do
  include Rack::Test::Methods

  describe '如何渲染返回值' do
    def app
      app = Class.new(Application)

      route = app.route('/request', :post)
        .do_any {
          response.body = [JSON.generate(name: 'Jim', age: '18', foo: 'foo')]
        }
        .if_status2(200) {
          expose :name, type: 'string'
          expose :age, type: 'integer'
        }

      app
    end

    it '渲染 name 和 age 属性' do
      post '/request'

      expect(JSON.parse(last_response.body)).to eq('name' => 'Jim', 'age' => 18)
    end
  end

  describe '值转换：transform' do
    def app
      app = Class.new(Application)

      route = app.route('/request', :post)
        .do_any {
          response.body = [JSON.generate(name: 'Jim', age: 18)]
        }
        .if_status2(200) {
          expose :name, type: 'string', transform: proc { |value| value.upcase }
          expose :age, type: 'integer', transform: proc { |value| value + 1 }
        }

      app
    end

    it '使用自定义行为渲染 name 和 age 属性' do
      post '/request'

      expect(JSON.parse(last_response.body)).to eq('name' => 'JIM', 'age' => 19)
    end
  end

  describe '提供值：value' do
    context '用在基本类型上' do
      def app
        app = Class.new(Application)

        route = app.route('/request', :post)
          .do_any {
            @name = 'Jim'
            @age = 18

            response.body = ['{}']
          }
          .if_status2(200) {
            expose :name, type: 'string', value: proc { @name } # TODO: lambda 表达式是不是可以检测参数个数
            expose :age, type: 'integer', value: proc { @age }
          }

        app
      end

      it '使用自定义行为渲染 name 和 age 属性' do
        post '/request'

        expect(JSON.parse(last_response.body)).to eq('name' => 'Jim', 'age' => 18)
      end
    end

    context '用在对象类型上' do
      def app
        app = Class.new(Application)

        route = app.route('/request', :post)
          .do_any {
            response.body = ['{}']
          }
          .if_status2(200) {
            expose :user, value: proc { { 'name' => 'Jim', 'age' => '18' } } do
              expose :name, type: 'string'
              expose :age, type: 'integer'
            end
          }

        app
      end

      it '使用自定义行为渲染 name 和 age 属性' do
        post '/request'

        expect(JSON.parse(last_response.body)).to eq('user' => { 'name' => 'Jim', 'age' => 18 })
      end
    end

    context '用在数组类型上' do
      def app
        app = Class.new(Application)

        route = app.route('/request', :post)
          .do_any {
            response.body = ['{}']
          }
          .if_status2(200) {
            expose :user, is_array: true, value: proc { [{ 'name' => 'Jim', 'age' => '18' }] } do
              expose :name, type: 'string'
              expose :age, type: 'integer'
            end
          }

        app
      end

      it '使用自定义行为渲染 name 和 age 属性' do
        post '/request'

        expect(JSON.parse(last_response.body)).to eq('user' => [{ 'name' => 'Jim', 'age' => 18 }])
      end
    end
  end
end
