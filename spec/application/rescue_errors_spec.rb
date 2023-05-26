require 'spec_helper'

describe Meta::Application, '.rescue_error' do
  include Rack::Test::Methods

  context '捕获通用异常' do
    context '中断 Execution 的执行' do
      def app
        Class.new(Meta::Application) do
          rescue_error StandardError do |e|
            response.status = 500
            response.body = ['Customized error!']
          end

          get '/request' do
            action do
              abort_execution!
            end
          end
        end
      end

      it '不会捕获 Meta::Execution::Abort' do
        get '/request'

        expect(last_response.status).to eq 200
      end
    end
  end

  context '捕获自定义异常' do
    let(:caught_error) { Class.new(StandardError) }
    let(:escaped_error) { Class.new(StandardError) }

    def app
      caught_error_holder = @caught_error_holder = []
      app = Class.new(Meta::Application)

      app.rescue_error(caught_error) { |e|
        response.status = 500
        response.body = ['Customized error!']
        caught_error_holder[0] = e
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
      expect(@caught_error_holder[0]).to be_instance_of(caught_error)
    end

    it 'raises not rescued error' do
      expect { get '/escaped' }.to raise_error(escaped_error)
    end

    context 'raising error in inner module' do
      let(:caught_by_inner_error) { Class.new(StandardError) }
      let(:caught_by_outer_error) { Class.new(StandardError) }
      let(:escaped_error) { Class.new(StandardError) }

      def app
        inner_app = Class.new(Meta::Application)

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

        app = Class.new(Meta::Application)
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

        inner_app = Class.new(Meta::Application)
        inner_app.rescue_error(caught_by_inner_error) {
          raise the_caught_by_outer_error
        }
        inner_app.route('/caught', :get)
          .do_any { raise the_caught_by_inner_error }

        app = Class.new(Meta::Application)
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

    describe 'Meta::Errors::NoMatchingRoute' do
      let(:holder) { {} }

      def rescue_error(app)
        the_holder = holder

        app.rescue_error(Meta::Errors::NoMatchingRoute) {
          the_holder[:rescued] = true
        }
      end

      shared_examples 'raises `Meta::Errors::NoMatchingRoute`' do
        it 'raises `Meta::Errors::NoMatchingRoute`' do
          expect {
            get '/unknown'
          }.to raise_error Meta::Errors::NoMatchingRoute
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
            Class.new(Meta::Application)
          end

          it_behaves_like 'raises `Meta::Errors::NoMatchingRoute`'
        end

        context 'defining `rescue_error`' do
          let(:holder) { {} }

          def app
            app = Class.new(Meta::Application)

            rescue_error(app)
            app
          end

          it_behaves_like 'rescues'
        end
      end

      context 'applying modules' do
        context 'not defining `rescue_error`' do
          def app
            app = Class.new(Meta::Application)

            app.apply Class.new(Meta::Application)
            app
          end

          it_behaves_like 'raises `Meta::Errors::NoMatchingRoute`'
        end

        context 'defining `rescue_error` in outer module' do
          let(:holder) { {} }

          def app
            app = Class.new(Meta::Application)
            app.apply Class.new(Meta::Application)

            rescue_error(app)
            app
          end

          it_behaves_like 'rescues'
        end

        context 'defining `rescue_error` in inner module' do
          def app
            app = Class.new(Meta::Application)

            inner_app = Class.new(Meta::Application)
            rescue_error(inner_app)

            app.apply inner_app
            app
          end

          it_behaves_like 'raises `Meta::Errors::NoMatchingRoute`'
        end
      end
    end
  end
end
