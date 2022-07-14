require 'spec_helper'
require 'json'
require 'grape-entity'
require_relative '../support/grape_entity_presenter_handler'


describe Dain::Application, '.exposures' do
  include Rack::Test::Methods

  describe '如何渲染返回值' do
    def app
      app = Class.new(Dain::Application)

      route = app.route('/request', :post)
        .do_any {
          response.body = [JSON.generate(name: 'Jim', age: '18', foo: 'foo')]
        }
        .if_status(200) {
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

  describe '值转换：convert' do
    def app
      app = Class.new(Dain::Application)

      route = app.route('/request', :post)
        .do_any {
          response.body = [JSON.generate(name: 'Jim', age: 18)]
        }
        .if_status(200) {
          expose :name, type: 'string', convert: proc { |value| value.upcase }
          expose :age, type: 'integer', convert: proc { |value| value + 1 }
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
        app = Class.new(Dain::Application)

        route = app.route('/request', :post)
          .do_any {
            @name = 'Jim'
            @age = 18

            response.body = ['{}']
          }
          .if_status(200) {
            expose :name, type: 'string', value: -> { @name }
            expose :age, type: 'integer', value: -> { @age }
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
        app = Class.new(Dain::Application)

        route = app.route('/request', :post)
          .do_any {
            response.body = ['{}']
          }
          .if_status(200) {
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
        app = Class.new(Dain::Application)

        route = app.route('/request', :post)
          .do_any {
            response.body = ['{}']
          }
          .if_status(200) {
            expose :user, type: 'array', value: proc { [{ 'name' => 'Jim', 'age' => '18' }] } do
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

  describe '渲染器：presenter' do
    let(:entity_class) do
      Class.new(Grape::Entity) do
        expose :name, :age
      end
    end

    let(:entity) do
      user = Object.new
      def user.name; 'Jim' end
      def user.age; 18 end
      user
    end

    before(:all) do
      Dain::JsonSchema::Presenters.register(GrapeEntityPresenterHandler)
    end

    after(:all) do
      Dain::JsonSchema::Presenters.unregister(GrapeEntityPresenterHandler)
    end

    def app
      app = Class.new(Dain::Application)

      the_entity_class = entity_class
      the_entity = entity

      route = app.route('/request', :post)
        .do_any {
          response.body = ['{}']
        }
        .if_status(200) {
          expose :user, presenter: the_entity_class, value: proc { the_entity }
        }

      app
    end

    it '使用自定义行为渲染 name 和 age 属性' do
      post '/request'

      expect(JSON.parse(last_response.body)).to eq('user' => { 'name' => 'Jim', 'age' => 18 })
    end
  end

  # spec/application/base/params_spec.rb 下的测试皆是语法糖
  describe '结构性语法' do
    describe '基本结构' do
      def app
        app = Class.new(Dain::Application)

        route = app.route('/request', :post)
          .do_any {
            response.body = [JSON.generate(name: 'Jim', age: '18', foo: 'foo')]
          }
          .if_status(200) {
            property :name, type: 'string'
            property :age, type: 'integer'
          }

        app
      end

      it '渲染 name 和 age 属性' do
        post '/request'

        expect(JSON.parse(last_response.body)).to eq('name' => 'Jim', 'age' => 18)
      end
    end

    describe '对象结构' do
      context '使用 properties 属性' do
        def app
          app = Class.new(Dain::Application)

          route = app.route('/request', :post)
            .do_any {
              response.body = [JSON.generate(user: { name: 'Jim', age: '18', foo: 'foo' }, bar: 'bar')]
            }
            .if_status(200) {
              property :user, type: 'object', properties: {
                name: { type: 'string' },
                age: { type: 'integer' },
              }
            }

          app
        end

        it '渲染 user 对象' do
          post '/request'

          expect(JSON.parse(last_response.body)).to eq('user' =>  { 'name' => 'Jim', 'age' => 18 })
        end

        context '内部还有个对象' do
          def app
            app = Class.new(Dain::Application)

            route = app.route('/request', :post)
              .do_any {
                response.body = [JSON.generate(user: { name: 'Jim', age: '18', address: { city: 'C', street: 'S', foo: 'foo' } }, bar: 'bar')]
              }
              .if_status(200) {
                property :user, type: 'object', properties: {
                  address: { type: 'object', properties: {
                    city: { type: 'string' },
                    street: { type: 'string' }
                  } }
                }
              }

            app
          end

          it '渲染 user 对象' do
            post '/request'

            expect(JSON.parse(last_response.body)).to eq('user' =>  { 'address' => { 'city' => 'C', 'street' => 'S' }})
          end
        end
      end

      context '使用块' do
        def app
          app = Class.new(Dain::Application)

          route = app.route('/request', :post)
            .do_any {
              response.body = [JSON.generate(user: { name: 'Jim', age: '18', foo: 'foo' }, bar: 'bar')]
            }
            .if_status(200) {
              property :user, type: 'object' do
                property :name, type: 'string'
                property :age, type: 'integer'
              end
            }

          app
        end

        it '渲染 user 对象' do
          post '/request'

          expect(JSON.parse(last_response.body)).to eq('user' =>  { 'name' => 'Jim', 'age' => 18 })
        end

        context '内部继续使用块' do
          def app
            app = Class.new(Dain::Application)

            route = app.route('/request', :post)
              .do_any {
                response.body = [JSON.generate(user: { name: 'Jim', age: '18', address: { city: 'C', street: 'S', foo: 'foo' } }, bar: 'bar')]
              }
              .if_status(200) {
                property :user, type: 'object' do
                  property :address, type: 'object' do
                    property :city, type: 'string'
                    property :street, type: 'string'
                  end
                end
              }

            app
          end

          it '渲染 user 对象' do
            post '/request'

            expect(JSON.parse(last_response.body)).to eq('user' =>  { 'address' => { 'city' => 'C', 'street' => 'S' }})
          end
        end

        context '内部使用 properties' do
          def app
            app = Class.new(Dain::Application)

            route = app.route('/request', :post)
              .do_any {
                response.body = [JSON.generate(user: { name: 'Jim', age: '18', address: { city: 'C', street: 'S', foo: 'foo' } }, bar: 'bar')]
              }
              .if_status(200) {
                property :user, type: 'object' do
                  property :address, type: 'object', properties: {
                    city: { type: 'string' },
                    street: { type: 'string' }
                  }
                end
              }

            app
          end

          it '渲染 user 对象' do
            post '/request'

            expect(JSON.parse(last_response.body)).to eq('user' =>  { 'address' => { 'city' => 'C', 'street' => 'S' }})
          end
        end
      end
    end
  end

  describe '数组结构' do
    context '无 items 定义' do
      def app
        app = Class.new(Dain::Application)

        route = app.route('/request', :post)
          .do_any {
            response.body = [JSON.generate(an_array: ['1', 2, '3'])]
          }
          .if_status(200) {
            property :an_array, type: 'array'
          }

        app
      end

      it '渲染普通数组' do
        post '/request'

        expect(JSON.parse(last_response.body)).to eq('an_array' => ['1', 2, '3'])
      end
    end

    context '使用 items' do
      context '简单数组' do
        def app
          app = Class.new(Dain::Application)

          route = app.route('/request', :post)
            .do_any {
              response.body = [JSON.generate(an_array: ['1', 2, '3'])]
            }
            .if_status(200) {
              property :an_array, type: 'array', items: { type: 'integer' }
            }

          app
        end

        it '渲染 user 对象' do
          post '/request'

          expect(JSON.parse(last_response.body)).to eq('an_array' => [1, 2, 3])
        end
      end

      context '内部使用 properties 定义对象' do
        def app
          app = Class.new(Dain::Application)

          route = app.route('/request', :post)
            .do_any {
              response.body = [JSON.generate(users: [{ name: 'Jim', age: '18', bar: 'bar' }])]
            }
            .if_status(200) {
              property :users, type: 'array', items: { 
                type: 'object', properties: {
                  name: { type: 'string' },
                  age: { type: 'integer' }
                }
              }
            }

          app
        end

        it '渲染 users 数组' do
          post '/request'

          expect(JSON.parse(last_response.body)).to eq('users' => [{ 'name' => 'Jim', 'age' => 18 }])
        end
      end
    end

    context '内部使用块定义对象' do
      def app
        app = Class.new(Dain::Application)

        route = app.route('/request', :post)
          .do_any {
            response.body = [JSON.generate(users: [{ name: 'Jim', age: '18', bar: 'bar' }])]
          }
          .if_status(200) {
            property :users, type: 'array' do
              property :name, type: 'string'
              property :age, type: 'integer'
            end
          }

        app
      end

      it '渲染 users 数组' do
        post '/request'

        expect(JSON.parse(last_response.body)).to eq('users' => [{ 'name' => 'Jim', 'age' => 18 }])
      end
    end
  end

  describe '数组和对象混合的复杂结构' do
    def app
      app = Class.new(Dain::Application)

      route = app.route('/request', :post)
        .do_any {
          response.body = [JSON.generate(
            data: {
              users: [
                {
                  name: 'Jim',
                  age: 18,
                  address: {
                    city: 'C',
                    street: 'S',
                    f3: 'f3'
                  }
                }
              ],
              f2: 'f2'
            },
            f1: 'f1'
          )]
        }
          .if_status(200) {
            property :data, type: 'object' do
              property :users, type: 'array' do
                property :address, type: 'object', properties: {
                  city: { type: 'string' },
                  street: { type: 'string' }
                }
              end
            end
          }

        app
    end

    it '渲染 users 数组' do
      post '/request'

      expect(JSON.parse(last_response.body)).to eq(
        'data' => {
          'users' => [
            {
              'address' => {
                'city' => 'C',
                'street' => 'S'
              }
            }
          ]
        }
      )
    end
  end
end
