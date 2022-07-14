require 'spec_helper'
require 'json'
require_relative '../../lib/entity'

describe Dain::Application, '.param' do
  include Rack::Test::Methods

  let(:holder) { {} }

  def app
    app = Class.new(Dain::Application)

    route = app.route('/request', :post)
    define_route(route)

    the_holder = holder
    route.do_any { the_holder[:params] = params }

    app
  end

  before do
    @holder = {}
  end

  describe 'declarings' do
    def app
      holder = @holder

      app = Class.new(Dain::Application)

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

      app = Class.new(Dain::Application)

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
      }.to raise_error(Dain::Errors::ParameterInvalid) { |e|
        expect(e.errors).to match('age' => a_string_including('类型转化出现错误'))
      }
    end

    describe 'no providing `type` option' do
      let(:holder) { {} }

      def app
        the_holder = holder
        the_extract_params = method(:extract_params)

        app = Class.new(Dain::Application)

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

    describe 'array type' do
      def app
        app = Class.new(Dain::Application)

        the_holder = holder
        route = app.route('/request', :post)
        define_route(route)
        route.do_any { the_holder[:params] = params }

        app
      end

      # TODO: 不支持 "type[]" style
      context 'setting type as "string[]" style' do
        def define_route(route)
          the_holder = holder
          route.params {
            param :an_array, type: 'array', items: { type: 'integer' }
          }
        end

        it '是 `type: "integer", is_array: true` 选项的语法糖' do
          post('/request', JSON.generate({ an_array: ['1', 2, '3'] }), { 'CONTENT_TYPE' => 'application/json' })
          expect(holder[:params]).to eq(an_array: [1, 2, 3])

          expect {
            post('/request', JSON.generate({ an_array: "1,2,3" }), { 'CONTENT_TYPE' => 'application/json' })
          }.to raise_error(Dain::Errors::ParameterInvalid)
        end
      end

      # TODO: 不支持 "array<type>" style
      context 'setting type as "array<string>" style' do
        def define_route(route)
          the_holder = holder
          route.params {
            param :an_array, type: 'array', items: { type: 'integer' }
          }
        end

        it '是 `type: "integer", is_array: true` 选项的语法糖' do
          post('/request', JSON.generate({ an_array: ['1', 2, '3'] }), { 'CONTENT_TYPE' => 'application/json' })
          expect(holder[:params]).to eq(an_array: [1, 2, 3])

          expect {
            post('/request', JSON.generate({ an_array: "1,2,3" }), { 'CONTENT_TYPE' => 'application/json' })
          }.to raise_error(Dain::Errors::ParameterInvalid)
        end
      end

      context 'setting type as "array"' do
        def define_route(route)
          the_holder = holder
          route.params {
            param :an_array, type: 'array'
          }
        end

        it '是 `is_array: true` 选项的语法糖' do
          post('/request', JSON.generate({ an_array: ['1', 2, '3'] }), { 'CONTENT_TYPE' => 'application/json' })
          expect(holder[:params]).to eq(an_array: ['1', 2, '3'])

          expect {
            post('/request', JSON.generate({ an_array: "1,2,3" }), { 'CONTENT_TYPE' => 'application/json' })
          }.to raise_error(Dain::Errors::ParameterInvalid)
        end
      end
    end
  end

  describe 'default' do
    def app
      holder = @holder

      app = Class.new(Dain::Application)

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
        app = Class.new(Dain::Application)

        the_holder = holder
        app.route('/users', :post)
          .params {
            param :user do
              param :name, type: 'string', required: true
              param :age, type: 'integer', default: 18
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
        }.to raise_error(Dain::Errors::ParameterInvalid) { |e|
          expect(e.errors['user.name']).to eq('未提供')
        }
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

        app = Class.new(Dain::Application)

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

          app = Class.new(Dain::Application)

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
          app = Class.new(Dain::Application)

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
          }.to raise_error(Dain::Errors::ParameterInvalid)
        end

        context 'when outer param is an array' do
          def app
            holder = @holder

            app = Class.new(Dain::Application)

            app.route('/users', :post)
              .params {
                param :users, type: 'array' do
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
            }.to raise_error(Dain::Errors::ParameterInvalid)
          end
        end
      end
    end
  end

  describe 'path params' do
    def app
      holder = @holder

      app = Class.new(Dain::Application)

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

  # TODO: 似乎可更新个名称
  describe 'is_array' do
    context 'providing type' do
      def app
        app = Class.new(Dain::Application)

        the_holder = holder
        app.route('/request', :post)
          .params {
            param(:an_array, type: 'array', items: { type: 'integer' })
          }
          .do_any { the_holder[:params] = params }

        app
      end

      # TODO: 传递空值给数组参数
      # TODO: 嵌套的咋说？

      it 'raises error if it does not pass array params' do
        expect {
          post('/request', JSON.generate(an_array: 1), { 'CONTENT_TYPE' => 'application/json' })
        }.to raise_error(Dain::Errors::ParameterInvalid)
      end

      it 'passes and converts type if it passes array params' do
        post('/request', JSON.generate(an_array: [1, '2']), { 'CONTENT_TYPE' => 'application/json' })

        expect(holder[:params]).to eq(an_array: [1, 2])
      end

      it 'raises error if type is not compatible' do
        expect {
          post('/request', JSON.generate(an_array: [1, 'x2']), { 'CONTENT_TYPE' => 'application/json' })
        }.to raise_error(Dain::Errors::ParameterInvalid)
      end
    end

    context 'not providing type' do
      def app
        app = Class.new(Dain::Application)

        the_holder = holder
        app.route('/request', :post)
          .params {
            param(:an_array, type: 'array')
          }
          .do_any { the_holder[:params] = params }

        app
      end

      it 'raises error if it does not pass array params' do
        expect {
          post('/request', JSON.generate(an_array: 1), { 'CONTENT_TYPE' => 'application/json' })
        }.to raise_error(Dain::Errors::ParameterInvalid)
      end

      it 'passes if it passes array params' do
        post('/request', JSON.generate(an_array: [1, '2', 'x3']), { 'CONTENT_TYPE' => 'application/json' })

        expect(holder[:params]).to eq(an_array: [1, '2', 'x3'])
      end
    end

    describe 'nesting' do
      def app
        the_holder = holder

        app = Class.new(Dain::Application)

        app.route('/users', :post)
          .params {
            param :users, type: 'array' do
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
        }.to raise_error(Dain::Errors::ParameterInvalid)
      end
    end
  end

  describe 'validations' do
    # 为字符串类型的参数提供正则表达式约束
    describe 'format' do
      def app
        the_holder = holder

        app = Class.new(Dain::Application)

        app.route('/request', :post)
          .params {
            param :a_str, type: 'string', format: /^x\d\d$/
          }
          .do_any { the_holder[:params] = params }

          app
      end

      it 'passes when param is fit for format' do
        post('/request', JSON.generate(a_str: 'x01'), { 'CONTENT_TYPE' => 'application/json' })

        expect(holder[:params]).to eq(a_str: 'x01')
      end

      it 'raises error when param is not for format' do
        expect {
          post('/request', JSON.generate(a_str: 'x001'), { 'CONTENT_TYPE' => 'application/json' })
        }.to raise_error(Dain::Errors::ParameterInvalid) { |e|
          expect(e.errors).to eq('a_str' => '格式不正确')
        }
      end
    end

    describe 'required' do
      def define_route(route)
        route.params {
          param :name, type: 'string', required: true
          param :age
        }
      end

      it 'passes when passing required params' do
        post('/request', JSON.generate(name: 'Jim'), { 'CONTENT_TYPE' => 'application/json' })

        expect(last_response).to be_ok
        expect(holder[:params]).to eq(name: 'Jim', age: nil)
      end

      it 'raises error when missing required params' do
        expect {
          post('/request', JSON.generate(name: nil, age: 18), { 'CONTENT_TYPE' => 'application/json' })
        }.to raise_error(Dain::Errors::ParameterInvalid)
      end

      it 'raises error when missing required params' do
        expect {
          post('/request', JSON.generate(age: 18), { 'CONTENT_TYPE' => 'application/json' })
        }.to raise_error(Dain::Errors::ParameterInvalid)
      end

      it '空字符串也要被报告错误' do
        expect {
          post('/request', JSON.generate(name: '', age: 18), { 'CONTENT_TYPE' => 'application/json' })
        }.to raise_error(Dain::Errors::ParameterInvalid)
      end
    end

    describe '报错时的参数路径如何显示' do
      describe 'PrimitiveScope::Validators' do
        context '最外层参数异常' do
          def define_route(route)
            route.params {
              param :a_str, type: 'string', format: /^x\d\d$/
            }
          end

          it 'raises error' do
            expect {
              post('/request', JSON.generate(a_str: 'x001'), { 'CONTENT_TYPE' => 'application/json' })
            }.to raise_error(Dain::Errors::ParameterInvalid) { |e|
              expect(e.errors).to include('a_str')
            }
          end
        end

        context '包裹一层对象嵌套' do
          def define_route(route)
            route.params {
              param :a_object, type: 'object' do
                param :a_str, type: 'string', format: /^x\d\d$/
              end
            }
          end

          it 'raises error' do
            expect {
              post('/request', JSON.generate(a_object: { a_str: 'x001' }), { 'CONTENT_TYPE' => 'application/json' })
            }.to raise_error(Dain::Errors::ParameterInvalid) { |e|
              expect(e.errors).to include('a_object.a_str')
            }
          end
        end

        context '包裹一层数组嵌套' do
          def define_route(route)
            route.params {
              param :a_object, type: 'array' do
                param :a_str, type: 'string', format: /^x\d\d$/
              end
            }
          end

          it 'raises error' do
            expect {
              post('/request', JSON.generate(a_object: [{ a_str: 'x01' }, { a_str: 'x001' }]), { 'CONTENT_TYPE' => 'application/json' })
            }.to raise_error(Dain::Errors::ParameterInvalid) { |e| 
              expect(e.errors).to include('a_object[1].a_str')
            }
          end
        end
      end

      describe 'ObjectScope::Validators' do
        context '最外层参数异常' do
          def define_route(route)
            route.params {
              param :a_str, required: true
            }
          end

          it 'raises error' do
            expect {
              post('/request', JSON.generate({}), { 'CONTENT_TYPE' => 'application/json' })
            }.to raise_error(Dain::Errors::ParameterInvalid) { |e| 
              expect(e.errors).to include('a_str')
            }
          end
        end

        context '内层参数异常' do
          def define_route(route)
            route.params {
              param :a_object, type: 'object' do
                param :a_str, required: true
              end
            }
          end

          it '通过测试当外层对象值是 nil' do
            expect {
              post('/request', JSON.generate({ a_object: nil }), { 'CONTENT_TYPE' => 'application/json' })
            }.not_to raise_error
          end

          it 'raises error' do
            expect {
              post('/request', JSON.generate(a_object: {}), { 'CONTENT_TYPE' => 'application/json' })
            }.to raise_error(Dain::Errors::ParameterInvalid) { |e| 
              expect(e.errors).to include('a_object.a_str')
            }
          end
        end
      end
    end
  end

  describe '引入外部模块' do
    context '传递块' do
      def app
        @holder = {}
        the_holder = @holder

        block = proc {
          param :name
          param :age
        }

        app = Class.new(Dain::Application)
        app.route('/users', :post)
          .params {
            param(:user, type: 'object', &block)
          }
          .do_any { the_holder[:params] = params }
        app
      end

      it '正确处理参数' do
        post('/users', JSON.generate(user: { name: 'Jim', age: 18 }), { 'CONTENT_TYPE' => 'application/json' })
        expect(@holder[:params]).to eq(user: { name: 'Jim', age: 18 })
      end
    end

    context '执行块' do
      def app
        @holder = {}
        the_holder = @holder

        block = proc {
          param :name
          param :age
        }

        app = Class.new(Dain::Application)
        app.route('/users', :post)
          .params {
            param :user, type: 'object' do
              instance_eval(&block)
            end
          }
          .do_any { the_holder[:params] = params }
        app
      end

      it '正确处理参数' do
        post('/users', JSON.generate(user: { name: 'Jim', age: 18 }), { 'CONTENT_TYPE' => 'application/json' })
        expect(@holder[:params]).to eq(user: { name: 'Jim', age: 18 })
      end
    end

    describe '#use' do
      def app
        the_holder = holder
        the_proc = proc

        app = Class.new(Dain::Application)

        app.route('/users', :post)
          .params {
            param :user, type: 'object' do
              use the_proc
            end
          }
          .do_any { the_holder[:params] = params }

        app
      end

      context 'use(Proc)' do
        def app
          @holder = {}
          the_holder = @holder

          the_proc = Proc.new do
            param :name
            param :age
          end

          app = Class.new(Dain::Application)
          app.route('/users', :post)
            .params {
              param :user, type: 'object' do
                use the_proc
              end
            }
            .do_any { the_holder[:params] = params }
          app
        end

        it '正确处理参数' do
          post('/users', JSON.generate(user: { name: 'Jim', age: 18 }), { 'CONTENT_TYPE' => 'application/json' })
          expect(@holder[:params]).to eq(user: { name: 'Jim', age: 18 })
        end
      end

      context 'use(&:to_proc)' do
        def app
          @holder = {}
          the_holder = @holder

          the_proc = Proc.new do
            param :name
            param :age
          end

          the_object = Object.new
          the_object.define_singleton_method(:to_proc) { the_proc }
          the_object

          app = Class.new(Dain::Application)
          app.route('/users', :post)
            .params {
              param :user, type: 'object' do
                use the_object
              end
            }
            .do_any { the_holder[:params] = params }
          app
        end

        it '正确处理参数' do
          post('/users', JSON.generate(user: { name: 'Jim', age: 18 }), { 'CONTENT_TYPE' => 'application/json' })
          expect(@holder[:params]).to eq(user: { name: 'Jim', age: 18 })
        end
      end
    end

    describe 'using:' do
      context 'using: Proc' do
        def app
          @holder = {}
          the_holder = @holder

          the_proc = Proc.new do
            param :name
            param :age
          end

          app = Class.new(Dain::Application)
          app.route('/users', :post)
            .params {
              param :user, type: 'object', using: the_proc 
            }
            .do_any { the_holder[:params] = params }
          app
        end

        it '正确处理参数' do
          post('/users', JSON.generate(user: { name: 'Jim', age: 18 }), { 'CONTENT_TYPE' => 'application/json' })
          expect(@holder[:params]).to eq(user: { name: 'Jim', age: 18 })
        end
      end

      context 'using: ObjectScope' do
        def app
          @holder = {}
          the_holder = @holder

          the_scope = Dain::JsonSchema::ObjectSchema.new({
            name: Dain::JsonSchema::BaseSchema.new,
            age: Dain::JsonSchema::BaseSchema.new 
          })

          app = Class.new(Dain::Application)
          app.route('/users', :post)
            .params {
              param :user, type: 'object', using: the_scope
            }
            .do_any { the_holder[:params] = params }
          app
        end

        it '正确处理参数' do
          post('/users', JSON.generate(user: { name: 'Jim', age: 18 }), { 'CONTENT_TYPE' => 'application/json' })
          expect(@holder[:params]).to eq(user: { name: 'Jim', age: 18 })
        end
      end

      context 'using: &:to_scope' do
        def app
          @holder = {}
          the_holder = @holder

          the_entity = Object.new
          def the_entity.to_scope
            Dain::JsonSchema::ObjectSchema.new({
              name: Dain::JsonSchema::BaseSchema.new,
              age: Dain::JsonSchema::BaseSchema.new 
            })
          end

          app = Class.new(Dain::Application)
          app.route('/users', :post)
            .params {
              param :user, type: 'object', using: the_entity
            }
            .do_any { the_holder[:params] = params }
          app
        end

        it '正确处理参数' do
          post('/users', JSON.generate(user: { name: 'Jim', age: 18 }), { 'CONTENT_TYPE' => 'application/json' })
          expect(@holder[:params]).to eq(user: { name: 'Jim', age: 18 })
        end
      end

      context 'using: Entity' do
        context '简单的实体' do
          def app
            @holder = {}
            the_holder = @holder

            the_entity = Class.new(Dain::Entities::Entity) do
              param :name
              param :age
            end

            app = Class.new(Dain::Application)
            app.route('/users', :post)
              .params {
                param :user, type: 'object', using: the_entity 
              }
              .do_any { the_holder[:params] = params }
            app
          end

          it '正确处理参数' do
            post('/users', JSON.generate(user: { name: 'Jim', age: 18 }), { 'CONTENT_TYPE' => 'application/json' })
            expect(@holder[:params]).to eq(user: { name: 'Jim', age: 18 })
          end
        end

        context '内部使用 using' do
          def app
            @holder = {}
            the_holder = @holder

            address_entity = Class.new(Dain::Entities::Entity) do
              param :city
              param :street
            end
            user_entity = Class.new(Dain::Entities::Entity) do
              param :address, type: 'object', using: address_entity
            end

            app = Class.new(Dain::Application)
            app.route('/users', :post)
              .params {
                param :user, type: 'object', using: user_entity 
              }
              .do_any { the_holder[:params] = params }
            app
          end

          it '正确解析参数' do
            post('/users', JSON.generate(user: { address: { city: 'city', street: 'street' } }), { 'CONTENT_TYPE' => 'application/json' })
            expect(@holder[:params]).to eq(user: { address: { city: 'city', street: 'street' } })
          end
        end

        context '使用数组类型' do
          def app
            @holder = {}
            the_holder = @holder

            the_entity = Class.new(Dain::Entities::Entity) do
              param :name
              param :age
            end

            app = Class.new(Dain::Application)
            app.route('/users', :post)
              .params {
                param(:user, type: 'array', using: the_entity)
              }
              .do_any { the_holder[:params] = params }
            app
          end

          it '正确解析参数' do
            post('/users', JSON.generate(user: [{ name: 'Jim', age: 18 }]), { 'CONTENT_TYPE' => 'application/json' })
            expect(@holder[:params]).to eq(user: [{ name: 'Jim', age: 18 }])
          end
        end
      end
    end
  end

  describe '区分参数和返回值' do
    context '简单情形' do
      def app
        @holder = {}
        the_holder = @holder

        app = Class.new(Dain::Application)
        app.route('/users', :post)
          .params {
            property :id, param: false
            property :password, render: false
            property :name
            property :age
          }
          .do_any { 
            the_holder[:params] = params 
            response.body = [JSON.generate(id: 1, password: 'password', name: 'Jim', age: 18)]
          }
          .if_status(200) do
            property :id, param: false
            property :password, render: false
            property :name
            property :age
          end
        app
      end

      before do
        post('/users', JSON.generate(id: 0, password: 'password', name: 'Jim', age: 18), { 'CONTENT_TYPE' => 'application/json' })
      end

      it '正确解析参数' do
        expect(@holder[:params]).to eq(password: 'password', name: 'Jim', age: 18)
      end

      # 由于 scope: 'param' 和 scope: 'return' 的逻辑实现一致，所以只测试这一个用例即可
      it '正确解析返回值' do
        expect(JSON.parse(last_response.body)).to eq('id' => 1, 'name' => 'Jim', 'age' => 18)
      end
    end

    context '嵌套情形' do
      context '嵌套在对象内' do
        def app
          @holder = {}
          the_holder = @holder

          app = Class.new(Dain::Application)
          app.route('/users', :post)
            .params {
              param(:user, type: 'object') do
                property :id, param: false
                property :password, render: false
                property :address, type: 'object' do
                  property :city, param: false
                  property :street, render: false
                end
              end
            }
            .do_any { the_holder[:params] = params }
          app
        end

        it '正确解析参数' do
          post('/users', JSON.generate(user: { 
            id: 0, 
            password: 'password', 
            address: { city: 'city', street: 'street' } 
          }), { 'CONTENT_TYPE' => 'application/json' })
          expect(@holder[:params]).to eq(user: { password: 'password', address: { street: 'street' } })
        end
      end

      context '嵌套在数组内' do
        def app
          @holder = {}
          the_holder = @holder

          app = Class.new(Dain::Application)
          app.route('/users', :post)
            .params {
              param(:user, type: 'object') do
                property :id, param: false
                property :password, render: false
                property :addresses, type: 'array' do
                  property :city, param: false
                  property :street, render: false
                end
              end
            }
            .do_any { the_holder[:params] = params }
          app
        end

        it '正确解析参数' do
          post('/users', JSON.generate(user: { 
            id: 0, 
            password: 'password', 
            addresses: [{ city: 'city', street: 'street' }] 
          }), { 'CONTENT_TYPE' => 'application/json' })
          expect(@holder[:params]).to eq(user: { password: 'password', addresses: [{ street: 'street' }] })
        end
      end

      context '嵌套在对象之上' do
        def app
          @holder = {}
          the_holder = @holder

          app = Class.new(Dain::Application)
          app.route('/users', :post)
            .params {
              param(:user, type: 'object') do
                property :id, param: false
                property :password, render: false
                property :address_one, type: 'object', param: false do
                  property :city
                  property :street
                end
                property :address_two, type: 'object', render: false do
                  property :city
                  property :street
                end
              end
            }
            .do_any { the_holder[:params] = params }
          app
        end

        it '正确解析参数' do
          post('/users', JSON.generate(user: { 
            id: 0, 
            password: 'password', 
            address_one: { city: 'city one', street: 'street one' },
            address_two: { city: 'city two', street: 'street two' } 
          }), { 'CONTENT_TYPE' => 'application/json' })
          expect(@holder[:params]).to eq(user: { password: 'password', address_two: { city: 'city two', street: 'street two' } })
        end
      end

      context '嵌套在数组之上' do
        def app
          @holder = {}
          the_holder = @holder

          app = Class.new(Dain::Application)
          app.route('/users', :post)
            .params {
              param(:user, type: 'object') do
                property :id, param: false
                property :password, render: false
                property :address_one, type: 'array', param: false do
                  property :city
                  property :street
                end
                property :address_two, type: 'array', render: false do
                  property :city
                  property :street
                end
              end
            }
            .do_any { the_holder[:params] = params }
          app
        end

        it '正确解析参数' do
          post('/users', JSON.generate(user: { 
            id: 0, 
            password: 'password', 
            address_one: [{ city: 'city one', street: 'street one' }],
            address_two: [{ city: 'city two', street: 'street two' }] 
          }), { 'CONTENT_TYPE' => 'application/json' })
          expect(@holder[:params]).to eq(user: { password: 'password', address_two: [{ city: 'city two', street: 'street two' }] })
        end
      end
    end

    context '引用外部模块' do
      def app
        @holder = {}
        the_holder = @holder

        the_entity = Class.new(Dain::Entities::Entity) do
          property :name
          property :age
        end

        app = Class.new(Dain::Application)
        app.route('/users', :post)
          .params {
            param :user, type: 'object', using: the_entity, param: false
          }
          .do_any { the_holder[:params] = params }
        app
      end

      it '正确解析参数' do
        post('/users', JSON.generate(user: { name: 'Jim', age: 18 }), { 'CONTENT_TYPE' => 'application/json' })
        expect(@holder[:params][:user]).to be nil
      end
    end
  end

  context '定义简单代码' do
    def app
      @holder = {}
      the_holder = @holder

      app = Class.new(Dain::Application)
      app.route('/users', :post)
        .params(type: 'string')
        .do_any { the_holder[:params] = params }
      app
    end

    it '正确解析参数' do
      post('/users', JSON.generate('Jim'), { 'CONTENT_TYPE' => 'application/json' })
      expect(@holder[:params]).to eq 'Jim'
    end
  end
end
