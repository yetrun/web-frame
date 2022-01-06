require_relative '../test_helper'
require 'json'

describe Application, '.param' do
  include Rack::Test::Methods

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
          param :name, type: String 
          param :age, type: Integer 
        }
        .do_any { holder[:params] = params }

      app
    end

    it 'returns right params when matching types' do
      post('/users', JSON.generate(name: 'Jim', age: 18), { 'CONTENT_TYPE' => 'application/json' })

      expect(last_response).to be_ok
      expect(@holder[:params]).to eq(name: 'Jim', age: 18)
    end

    it 'raises error when not matching some types' do
      expect { 
        post('/users', JSON.generate(name: 'Jim', age: '18'), { 'CONTENT_TYPE' => 'application/json' })
      }.to raise_error(Errors::ParameterInvalid)
    end
  end

  describe 'required' do
    def app
      holder = @holder

      app = Class.new(Application)

      app.route('/users', :post)
        .params {
          param :name, required: true 
          param :age  # required 选项的默认值是 `false`
        }
        .do_any { holder[:params] = params }

      app
    end

    it 'passes when passing required params' do
      post('/users', JSON.generate(name: 'Jim'), { 'CONTENT_TYPE' => 'application/json' })

      expect(last_response).to be_ok
      expect(@holder[:params]).to eq(name: 'Jim', age: nil)
    end

    it 'raises error when missing required params' do
      expect { 
        post('/users', JSON.generate(name: nil, age: 18), { 'CONTENT_TYPE' => 'application/json' })
      }.to raise_error(Errors::ParameterInvalid)
    end

    it 'raises error when passing nil to required params' do
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
        holder = @holder

        app = Class.new(Application)

        app.route('/users', :post)
          .params {
            param :user do
              param :name, type: String, required: true
              param :age, type: Integer, default: 18
            end
          }
          .do_any { holder[:params] = params }

          app
      end

      it 'supports passing nesting params' do
        post('/users', JSON.generate(user: { name: 'Jim', age: 18, bar: 'bar' }, foo: 'foo'), { 'CONTENT_TYPE' => 'application/json' })

        expect(@holder[:params]).to eq(user: { name: 'Jim', age: 18 })
      end

      it 'supports passing `required` option' do
        expect {
          post('/users', JSON.generate(user: { age: 18 }), { 'CONTENT_TYPE' => 'application/json' })
        }.to raise_error(Errors::ParameterInvalid)
      end

      it 'supports passing `type` option' do
        expect {
          post('/users', JSON.generate(user: { name: 'Jim', age: '18' }), { 'CONTENT_TYPE' => 'application/json' })
        }.to raise_error(Errors::ParameterInvalid)
      end

      it 'supports passing `default` option' do
        post('/users', JSON.generate(user: { name: 'Jim' }), { 'CONTENT_TYPE' => 'application/json' })

        expect(@holder[:params]).to eq(user: { name: 'Jim', age: 18 })
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

    context 'the outer param is an Array' do
      def app
        holder = @holder

        app = Class.new(Application)

        app.route('/users', :post)
          .params {
            param :users, type: Array do
              param :name
              param :age
            end
          }
          .do_any { holder[:params] = params }

          app
      end

      it 'supports nesting array params' do
        post('/users', JSON.generate(users: [{ name: 'Jim', age: 18 }, { name: 'James', age: 19 }]), { 'CONTENT_TYPE' => 'application/json' })

        expect(@holder[:params]).to eq(users: [{ name: 'Jim', age: 18 }, { name: 'James', age: 19 }])
      end

      it 'raises error when passing a hash' do
        expect {
          post('/users', JSON.generate(users: { name: 'Jim', age: 18 }), { 'CONTENT_TYPE' => 'application/json' })
        }.to raise_error(Errors::ParameterInvalid)
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
          holder = @holder

          app = Class.new(Application)

          app.route('/users', :post)
            .params {
              param :user, type: Hash do
                param :name
                param :age
              end
            }
              .do_any { holder[:params] = params }

            app
        end

        it 'supports passing empty hash to outer params' do
          post('/users', JSON.generate({}), { 'CONTENT_TYPE' => 'application/json' })

          expect(@holder[:params]).to eq(user: nil)
        end

        it 'supports passing empty hash to inner params' do
          post('/users', JSON.generate(user: {}), { 'CONTENT_TYPE' => 'application/json' })

          expect(@holder[:params]).to eq(user: { name: nil, age: nil })
        end

        it 'supports passing nil to inner params' do
          post('/users', JSON.generate(user: nil), { 'CONTENT_TYPE' => 'application/json' })

          expect(@holder[:params]).to eq(user: nil)
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
                param :users, type: Array do
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
          param :id, type: String
        }
        .do_any { holder[:params] = params }

        app
    end

    it 'gets params from request path' do
      get '/users/1'

      expect(@holder[:params]).to eq(id: '1')
    end
  end
end
