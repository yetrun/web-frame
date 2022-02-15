require 'spec_helper'
require 'json'

describe Application, '.param' do
  include Rack::Test::Methods

  let(:holder) { {} }

  before do
    @holder = {}
  end

  describe 'declarings' do
    def app
      holder = @holder

      app = Class.new(Application)

      app.route('/users', :post)
        .params {
          param :name
          param :age
        } 
        .do_any { holder[:params] = params }

      app
    end

    it 'filters out undeclared params' do
      post('/users', JSON.generate(name: 'Jim', age: 18, foo: 'bar'), { 'CONTENT_TYPE' => 'application/json' })

      expect(last_response).to be_ok

      expect(@holder[:params]).to eq(name: 'Jim', age: 18)
    end
  end

  describe 'types' do
    def app
      holder = @holder

      app = Class.new(Application)

      app.route('/users', :post)
        .params {
          param :name, type: 'string' 
          param :age, type: 'integer' 
        }
        .do_any { holder[:params] = params }

      app
    end

    it 'returns right params when matching types' do
      post('/users', JSON.generate(name: 'Jim', age: 18), { 'CONTENT_TYPE' => 'application/json' })

      expect(last_response).to be_ok
      expect(@holder[:params]).to eq(name: 'Jim', age: 18)
    end

    it 'converts type when it is compatible' do
      post('/users', JSON.generate(name: 'Jim', age: '18'), { 'CONTENT_TYPE' => 'application/json' })

      expect(last_response).to be_ok
      expect(@holder[:params]).to eq(name: 'Jim', age: 18)
    end

    it 'raises error when it is not compatible' do
      expect { 
        post('/users', JSON.generate(name: 'Jim', age: 'a18'), { 'CONTENT_TYPE' => 'application/json' })
      }.to raise_error(Errors::ParameterInvalid)
    end

    describe 'no providing `type` option' do
      let(:holder) { {} }

      def app
        the_holder = holder
        the_extract_params = method(:extract_params)

        app = Class.new(Application)

        route = app.route('/users', :post)
        define_params(route)
        route.do_any { the_holder[:any_type_params] = the_extract_params.call(params) }

        app
      end

      shared_examples 'accepting any values' do
        it 'accepts primitive value' do
          post('/users', JSON.generate(provide_params('any value')), { 'CONTENT_TYPE' => 'application/json' })

          expect(last_response).to be_ok
          expect(holder[:any_type_params]).to eq 'any value'
        end

        it 'accepts array value' do
          post('/users', JSON.generate(provide_params(['value one', 'value two'])), { 'CONTENT_TYPE' => 'application/json' })

          expect(last_response).to be_ok
          expect(holder[:any_type_params]).to eq ['value one', 'value two']
        end

        it 'accepts hash value' do
          post('/users', JSON.generate(provide_params('a' => 1, 'b' => 2)), { 'CONTENT_TYPE' => 'application/json' })

          expect(last_response).to be_ok
          expect(holder[:any_type_params]).to eq('a' => 1, 'b' => 2)
        end
      end

      context '定义在最外层' do
        def define_params(route)
          route.params {
            param :any
          }
        end

        def provide_params(value)
          { any: value }
        end

        def extract_params(params)
          params[:any]
        end

        include_examples 'accepting any values'
      end

      context '定义在内层' do
        def define_params(route)
          route.params {
            param :nesting, type: 'object' do
              param :any
            end
          }
        end

        def provide_params(value)
          { nesting: { any: value } }
        end

        def extract_params(params)
          params[:nesting][:any]
        end

        include_examples 'accepting any values'
      end
    end
  end

  describe 'required' do
    def app
      the_holder = holder

      app = Class.new(Application)

      app.route('/users', :post)
        .params {
          param :name
          param :age

          required :name
        }
        .do_any { the_holder[:params] = params }

      app
    end

    it 'passes when passing required params' do
      post('/users', JSON.generate(name: 'Jim'), { 'CONTENT_TYPE' => 'application/json' })

      expect(last_response).to be_ok
      expect(holder[:params]).to eq(name: 'Jim', age: nil)
    end

    it 'raises error when missing required params' do
      expect { 
        post('/users', JSON.generate(name: nil, age: 18), { 'CONTENT_TYPE' => 'application/json' })
      }.to raise_error(Errors::ParameterInvalid)
    end

    it 'raises error when missing required params' do
      expect { 
        post('/users', JSON.generate(age: 18), { 'CONTENT_TYPE' => 'application/json' })
      }.to raise_error(Errors::ParameterInvalid)
    end
  end

  describe 'default' do
    def app
      holder = @holder

      app = Class.new(Application)

      app.route('/users', :post)
        .params {
          param :name 
          param :age, default: 18 
        }
        .do_any { holder[:params] = params }

      app
    end

    it 'sets default value when missing params' do
      post('/users', JSON.generate({}), { 'CONTENT_TYPE' => 'application/json' })

      expect(@holder[:params]).to eq(name: nil, age: 18)
    end

    it 'sets default value when passing nil' do
      post('/users', JSON.generate(age: nil), { 'CONTENT_TYPE' => 'application/json' })

      expect(@holder[:params]).to eq(name: nil, age: 18)
    end
  end

  describe 'nesting' do
    context 'in the inner block' do
      def app
        app = Class.new(Application)

        the_holder = holder
        app.route('/users', :post)
          .params {
            param :user do
              param :name, type: 'string'
              param :age, type: 'integer', default: 18

              required :name
            end
          }
          .do_any { the_holder[:params] = params }

        app
      end

      it 'supports passing nesting params' do
        post('/users', JSON.generate(user: { name: 'Jim', age: 18, bar: 'bar' }, foo: 'foo'), { 'CONTENT_TYPE' => 'application/json' })

        expect(holder[:params]).to eq(user: { name: 'Jim', age: 18 })
      end

      it 'supports passing `required` option' do
        expect {
          post('/users', JSON.generate(user: { age: 18 }), { 'CONTENT_TYPE' => 'application/json' })
        }.to raise_error(Errors::ParameterInvalid)
      end

      it 'supports passing `type` option' do
        post('/users', JSON.generate(user: { name: 'Jim', age: '18' }), { 'CONTENT_TYPE' => 'application/json' })

        expect(holder[:params]).to eq(user: { name: 'Jim', age: 18 })
      end

      it 'supports passing `default` option' do
        post('/users', JSON.generate(user: { name: 'Jim' }), { 'CONTENT_TYPE' => 'application/json' })

        expect(holder[:params]).to eq(user: { name: 'Jim', age: 18 })
      end
    end

    context 'in the more inner block' do
      def app
        holder = @holder

        app = Class.new(Application)

        app.route('/users', :post)
          .params {
            param :user do
              param :name
              param :age
              param :address do
                param :city
                param :street
              end
            end
          }
          .do_any { holder[:params] = params }

          app
      end

      it 'supports passing deeper nesting params' do
        post('/users', JSON.generate(user: { name: 'Jim', age: 18, address: { city: '上海', street: '南京西路', foo: 'foo' }}), { 'CONTENT_TYPE' => 'application/json' })

        expect(@holder[:params]).to eq(user: { name: 'Jim', age: 18, address: { city: '上海', street: '南京西路' }})
      end
    end

    describe 'passing nothing' do
      context 'no nesting' do
        def app
          holder = @holder

          app = Class.new(Application)

          app.route('/users', :post)
            .params {
              param :name
              param :age
            }
              .do_any { holder[:params] = params }

            app
        end

        it 'supports passing empty hash' do
          post('/users', JSON.generate({}), { 'CONTENT_TYPE' => 'application/json' })

          expect(@holder[:params]).to eq(name: nil, age: nil)
        end
      end

      context 'nesting' do
        def app
          app = Class.new(Application)

          the_holder = holder
          app.route('/users', :post)
            .params {
              param :user, type: 'object' do
                param :name
                param :age
              end
            }
            .do_any { the_holder[:params] = params }

          app
        end

        # TODO: 传递空值给对象参数

        it 'supports passing empty hash to outer params' do
          post('/users', JSON.generate({}), { 'CONTENT_TYPE' => 'application/json' })

          expect(holder[:params]).to eq(user: nil)
        end

        it 'supports passing empty hash to inner params' do
          post('/users', JSON.generate(user: {}), { 'CONTENT_TYPE' => 'application/json' })

          expect(holder[:params]).to eq(user: { name: nil, age: nil })
        end

        it 'supports passing nil to inner params' do
          post('/users', JSON.generate(user: nil), { 'CONTENT_TYPE' => 'application/json' })

          expect(holder[:params]).to eq(user: nil)
        end

        it 'raises error when passing not hash value to inner params' do
          expect {
            post('/users', JSON.generate(user: 'user'), { 'CONTENT_TYPE' => 'application/json' })
          }.to raise_error(Errors::ParameterInvalid)
        end

        context 'when outer param is an array' do
          def app
            holder = @holder

            app = Class.new(Application)

            app.route('/users', :post)
              .params {
                param :users, type: 'object', is_array: true do
                  param :name
                  param :age
                end
              }
              .do_any { holder[:params] = params }

              app
          end

          it 'supports passing empty hash to outer params' do
            post('/users', JSON.generate({}), { 'CONTENT_TYPE' => 'application/json' })

            expect(@holder[:params]).to eq(users: nil)
          end

          it 'supports passing empty array to inner params' do
            post('/users', JSON.generate(users: []), { 'CONTENT_TYPE' => 'application/json' })

            expect(@holder[:params]).to eq(users: [])
          end

          it 'supports passing nil to inner params' do
            post('/users', JSON.generate(users: nil), { 'CONTENT_TYPE' => 'application/json' })

            expect(@holder[:params]).to eq(users: nil)
          end

          it 'raise error when passing not array value to inner params' do
            expect {
              post('/users', JSON.generate(users: 'users'), { 'CONTENT_TYPE' => 'application/json' })
            }.to raise_error(Errors::ParameterInvalid)
          end
        end
      end
    end
  end

  describe 'path params' do
    def app
      holder = @holder

      app = Class.new(Application)

      app.route('/users/:id', :get)
        .params {
          param :id, type: 'string'
        }
        .do_any { holder[:params] = params }

      app
    end

    it 'gets params from request path' do
      get '/users/1'

      expect(@holder[:params]).to eq(id: '1')
    end
  end

  describe 'do not repeat yourself' do
    def app
      holder = @holder

      app = Class.new(Application)

      block = proc {
        param :name
        param :age
      }

      app.route('/users', :post)
        .params {
          param(:user, type: 'object', &block)
        }
        .do_any { holder[:params] = params }

      app.route('/users/:id', :put)
        .params {
          param :user, type: 'object' do
            instance_eval(&block)
          end
        }
        .do_any { holder[:params] = params }

      app
    end

    it 'retrieves right params when requesting POST /users' do
      post('/users', JSON.generate(user: { name: 'Jim', age: 18 }), { 'CONTENT_TYPE' => 'application/json' })

      expect(@holder[:params]).to eq(user: { name: 'Jim', age: 18 })
    end

    it 'retrieves right params when requesting PUT /users/:id' do
      put('/users/1', JSON.generate(user: { name: 'Jim', age: 18 }), { 'CONTENT_TYPE' => 'application/json' })

      expect(@holder[:params]).to eq(user: { name: 'Jim', age: 18})
    end
  end

  describe 'is_array' do
    context 'providing type' do
      def app
        app = Class.new(Application)

        the_holder = holder
        app.route('/request', :post)
          .params {
            param(:an_array, type: 'integer', is_array: true)
          }
          .do_any { the_holder[:params] = params }

        app
      end

      # TODO: 传递空值给数组参数
      # TODO: 嵌套的咋说？

      it 'raises error if it does not pass array params' do
        expect {
          post('/request', JSON.generate(an_array: 1), { 'CONTENT_TYPE' => 'application/json' })
        }.to raise_error(Errors::ParameterInvalid)
      end

      it 'passes and converts type if it passes array params' do
        post('/request', JSON.generate(an_array: [1, '2']), { 'CONTENT_TYPE' => 'application/json' })

        expect(holder[:params]).to eq(an_array: [1, 2])
      end

      it 'raises error if type is not compatible' do
        expect {
          post('/request', JSON.generate(an_array: [1, 'x2']), { 'CONTENT_TYPE' => 'application/json' })
        }.to raise_error(Errors::ParameterInvalid)
      end
    end

    context 'not providing type' do
      def app
        app = Class.new(Application)

        the_holder = holder
        app.route('/request', :post)
          .params {
            param(:an_array, is_array: true)
          }
          .do_any { the_holder[:params] = params }

          app
      end

      it 'raises error if it does not pass array params' do
        expect {
          post('/request', JSON.generate(an_array: 1), { 'CONTENT_TYPE' => 'application/json' })
        }.to raise_error(Errors::ParameterInvalid)
      end

      it 'passes if it passes array params' do
        post('/request', JSON.generate(an_array: [1, '2', 'x3']), { 'CONTENT_TYPE' => 'application/json' })

        expect(holder[:params]).to eq(an_array: [1, '2', 'x3'])
      end
    end

    describe 'nesting' do
      def app
        the_holder = holder

        app = Class.new(Application)

        app.route('/users', :post)
          .params {
            param :users, type: 'object', is_array: true do
              param :name
              param :age
            end
          }
          .do_any { the_holder[:params] = params }

        app
      end

      it 'supports nesting array params' do
        post('/users', JSON.generate(users: [{ name: 'Jim', age: 18 }, { name: 'James', age: 19 }]), { 'CONTENT_TYPE' => 'application/json' })

        expect(holder[:params]).to eq(users: [{ name: 'Jim', age: 18 }, { name: 'James', age: 19 }])
      end

      it 'raises error when passing a hash' do
        expect {
          post('/users', JSON.generate(users: { name: 'Jim', age: 18 }), { 'CONTENT_TYPE' => 'application/json' })
        }.to raise_error(Errors::ParameterInvalid)
      end
    end
  end

  # 为字符串类型的参数提供正则表达式约束
  describe 'format' do
    def app
      the_holder = holder

      app = Class.new(Application)

      app.route('/request', :post)
        .params {
          param :str, type: 'string', format: /^x\d\d$/
        }
        .do_any { the_holder[:params] = params }

        app
    end

    it 'passes when param is fit for format' do
      post('/request', JSON.generate(str: 'x01'), { 'CONTENT_TYPE' => 'application/json' })

      expect(holder[:params]).to eq(str: 'x01')
    end

    it 'raises error when param is not for format' do
      expect {
        post('/request', JSON.generate(str: 'x001'), { 'CONTENT_TYPE' => 'application/json' })
      }.to raise_error(Errors::ParameterInvalid)
    end
  end
end
