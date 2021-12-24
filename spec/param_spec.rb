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

  describe '参数嵌套' do
    context '两层嵌套' do
      def app
        holder = @holder

        app = Class.new(Application)

        app.route('/users', :post)
          .param(:user) do
            param :name, type: String, required: true
            param :age, type: Integer, default: 18
          end
            .do_any { holder[0] = params }

          app
      end

      it '传递两层嵌套参数' do
        post('/users', JSON.generate(user: { name: 'Jim', age: 18, bar: 'bar' }, foo: 'foo'), { 'CONTENT_TYPE' => 'application/json' })

        expect(@holder[0]).to eq(user: { name: 'Jim', age: 18 })
      end

      it '支持 required' do
        expect {
          post('/users', JSON.generate(user: { age: 18 }), { 'CONTENT_TYPE' => 'application/json' })
        }.to raise_error(Errors::ParameterInvalid)
      end

      it '支持 default' do
        post('/users', JSON.generate(user: { name: 'Jim' }), { 'CONTENT_TYPE' => 'application/json' })

        expect(@holder[0]).to eq(user: { name: 'Jim', age: 18 })
      end

      it '支持 type check' do
        expect {
          post('/users', JSON.generate(user: { name: 'Jim', age: '18' }), { 'CONTENT_TYPE' => 'application/json' })
        }.to raise_error(Errors::ParameterInvalid)
      end
    end

    context '三层嵌套' do
      def app
        holder = @holder

        app = Class.new(Application)

        app.route('/users', :post)
          .param(:user) do
            param :name
            param :age
            param :address do
              param :city
              param :street
            end
          end
            .do_any { holder[0] = params }

          app
      end

      it '传递三层嵌套参数' do
        post('/users', JSON.generate(user: { name: 'Jim', age: 18, address: { city: '上海', street: '南京西路', foo: 'foo' }}), { 'CONTENT_TYPE' => 'application/json' })

        expect(@holder[0]).to eq(user: { name: 'Jim', age: 18, address: { city: '上海', street: '南京西路' }})
      end
    end

    context '数组嵌套' do
      def app
        holder = @holder

        app = Class.new(Application)

        app.route('/users', :post)
          .param(:users, type: Array) do
            param :name
            param :age
          end
            .do_any { holder[0] = params }

          app
      end

      it '传递嵌套数组参数' do
        post('/users', JSON.generate(users: [{ name: 'Jim', age: 18 }, { name: 'James', age: 19 }]), { 'CONTENT_TYPE' => 'application/json' })

        expect(@holder[0]).to eq(users: [{ name: 'Jim', age: 18 }, { name: 'James', age: 19 }])
      end
    end

    describe '处理 null' do
      context '为嵌套的参数整体传递 null' do
        def app
          holder = @holder

          app = Class.new(Application)

          app.route('/users', :post)
            .param(:users) do
              param :name
              param :age
            end
              .do_any { holder[0] = params }

            app
        end

        it '为嵌套的参数整体传递 null' do
          post('/users', JSON.generate(users: nil), { 'CONTENT_TYPE' => 'application/json' })

          expect(@holder[0]).to eq(users: nil)
        end
      end

      context '为嵌套数组参数传递 null' do
        def app
          holder = @holder

          app = Class.new(Application)

          app.route('/users', :post)
            .param(:users, type: Array) do
              param :name
              param :age
            end
              .do_any { holder[0] = params }

            app
        end

        it '为嵌套数组参数传递 null' do
          post('/users', JSON.generate(users: nil), { 'CONTENT_TYPE' => 'application/json' })

          expect(@holder[0]).to eq(users: nil)
        end
      end

      context '为嵌套数组参数传递对象' do
        def app
          holder = @holder

          app = Class.new(Application)

          app.route('/users', :post)
            .param(:users, type: Array) do
              param :name
              param :age
            end
              .do_any { holder[0] = params }

            app
        end

        it '为嵌套数组参数传递对象' do
          expect {
            post('/users', JSON.generate(users: { name: 'Jim', age: 18 }), { 'CONTENT_TYPE' => 'application/json' })
          }.to raise_error(Errors::ParameterInvalid)
        end
      end
    end
  end
end
