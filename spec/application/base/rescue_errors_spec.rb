require 'spec_helper'

describe Application, '.rescue_error' do
  include Rack::Test::Methods

  context '捕获自定义异常' do
    let(:caught_error) { Class.new(StandardError) }
    let(:escaped_error) { Class.new(StandardError) }

    def app
      app = Class.new(Application)

      app.rescue_error(caught_error) {
        response.status = 500
        response.body = ['Customized error!']
      }

      the_caught_error = caught_error
      the_escaped_error = escaped_error

      app.route('/caught', :get)
        .do_any { raise the_caught_error }
      app.route('/escaped', :get)
        .do_any { raise the_escaped_error }

      app
    end

    it 'catch rescued error' do
      get '/caught'

      expect(last_response.status).to eq 500
      expect(last_response.body).to eq 'Customized error!'
    end

    it 'raises not rescued error' do
      expect { get '/escaped' }.to raise_error(escaped_error)
    end

    context 'raising error in inner module' do
      let(:caught_by_inner_error) { Class.new(StandardError) }
      let(:caught_by_outer_error) { Class.new(StandardError) }
      let(:escaped_error) { Class.new(StandardError) }

      def app
        inner_app = Class.new(Application)

        inner_app.rescue_error(caught_by_inner_error) {
          response.status = 500
          response.body = ['Caught by inner module!']
        }

        the_caught_by_inner_error = caught_by_inner_error
        the_caught_by_outer_error = caught_by_outer_error
        the_escaped_error = escaped_error

        inner_app.route('/caught/by_inner', :get)
          .do_any { raise the_caught_by_inner_error }
        inner_app.route('/caught/by_outer', :get)
          .do_any { raise the_caught_by_outer_error }
        inner_app.route('/escaped', :get)
          .do_any { raise the_escaped_error }

        app = Class.new(Application)
        app.rescue_error(caught_by_outer_error) {
          response.status = 500
          response.body = ['Caught by outer module!']
        }
        app.apply inner_app

        app
      end

      context 'defining `rescue_error` in inner module' do
        it 'rescues' do
          get '/caught/by_inner'

          expect(last_response.status).to eq 500
          expect(last_response.body).to eq 'Caught by inner module!'
        end
      end

      context 'defining `rescue_error` in outer module' do
        it 'rescues' do
          get '/caught/by_outer'

          expect(last_response.status).to eq 500
          expect(last_response.body).to eq 'Caught by outer module!'
        end
      end

      context 'missing defining' do
        it 'raises error' do
          expect { get '/escaped' }.to raise_error(escaped_error)
        end
      end
    end

    context 'raising error again in inner module' do
      let(:caught_by_inner_error) { Class.new(StandardError) }
      let(:caught_by_outer_error) { Class.new(StandardError) }

      def app
        the_caught_by_inner_error = caught_by_inner_error
        the_caught_by_outer_error = caught_by_outer_error

        inner_app = Class.new(Application)
        inner_app.rescue_error(caught_by_inner_error) {
          raise the_caught_by_outer_error
        }
        inner_app.route('/caught', :get)
          .do_any { raise the_caught_by_inner_error }

        app = Class.new(Application)
        app.rescue_error(caught_by_outer_error) {
          response.status = 500
          response.body = ['Caught by outer module!']
        }
        app.apply inner_app

        app
      end

      context 'defining `resuce_error` in outer module' do
        it 'rescues' do
          get '/caught'

          expect(last_response.status).to eq 500
          expect(last_response.body).to eq 'Caught by outer module!'
        end
      end
    end

    describe 'Errors::NoMatchingRoute' do
      let(:holder) { {} }

      def rescue_error(app)
        the_holder = holder

        app.rescue_error(Errors::NoMatchingRoute) {
          the_holder[:rescued] = true
        }
      end

      shared_examples 'raises `Errors::NoMatchingRoute`' do
        it 'raises `Errors::NoMatchingRoute`' do
          expect {
            get '/unknown'
          }.to raise_error Errors::NoMatchingRoute
        end
      end

      shared_examples 'rescues' do
        it 'rescues' do
          get '/unknown'

          expect(holder[:rescued]).to be true
        end
      end

      context 'not applying modules' do
        context 'not defining `rescue_error`' do
          def app
            Class.new(Application)
          end

          it_behaves_like 'raises `Errors::NoMatchingRoute`'
        end

        context 'defining `rescue_error`' do
          let(:holder) { {} }

          def app
            app = Class.new(Application)

            rescue_error(app)
            app
          end

          it_behaves_like 'rescues'
        end
      end

      context 'applying modules' do
        context 'not defining `rescue_error`' do
          def app
            app = Class.new(Application)

            app.apply Class.new(Application)
            app
          end

          it_behaves_like 'raises `Errors::NoMatchingRoute`'
        end

        context 'defining `rescue_error` in outer module' do
          let(:holder) { {} }

          def app
            app = Class.new(Application)
            app.apply Class.new(Application)

            rescue_error(app)
            app
          end

          it_behaves_like 'rescues'
        end

        context 'defining `rescue_error` in inner module' do
          def app
            app = Class.new(Application)

            inner_app = Class.new(Application)
            rescue_error(inner_app)

            app.apply inner_app
            app
          end

          it_behaves_like 'raises `Errors::NoMatchingRoute`'
        end
      end
    end
  end

  context '捕获参数异常' do
    def app
      app = Class.new(Application)
      app.route('/users', :post)
        .params {
          param :user do
            param :name, type: 'string'
            param :age, type: 'integer'
            param :date, type: 'string', format: /\d{4}-\d{2}-\d{2}/

            required :name
          end

          required :user
        }
      app
    end

    it '报告所有内部参数的异常' do
      expect {
        post('/users', JSON.generate(user: {
          age: 'a18',
          date: '1234'
        }), { 'CONTENT_TYPE' => 'application/json' })
      }.to raise_error(Errors::ParameterInvalid) { |e|
        expect(e.errors).to match(
          'user.name' => '未提供',
          'user.age' => a_string_including('类型转化出现错误'),
          'user.date' => '格式不正确'
        )
      }
    end

    it '报告外部参数的异常' do
      expect {
        post('/users', JSON.generate({}), { 'CONTENT_TYPE' => 'application/json' })
      }.to raise_error(Errors::ParameterInvalid) { |e|
        expect(e.errors).to eq('user' => '未提供')
      }
    end
  end
end
