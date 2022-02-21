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
        .if_status2(200) do
          expose :name, type: 'string'
          expose :age, type: 'integer'
        end

      app
    end

    it '渲染 name 和 age 属性' do
      post '/request'

      expect(JSON.parse(last_response.body)).to eq('name' => 'Jim', 'age' => 18)
    end
  end
end
