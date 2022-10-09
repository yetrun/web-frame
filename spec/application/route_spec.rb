require 'spec_helper'
require 'support/shared_examples'

describe Dain::Application, '.route' do
  include Rack::Test::Methods

  def app
    app = Class.new(Dain::Application)

    app.route('/users', :get)
    app.route('/users', :post)
    app.route('/posts', :get)

    app
  end

  describe 'matched routes' do
    include_examples 'matching route', :get, '/users'
    include_examples 'matching route', :post, '/users'
    include_examples 'matching route', :get, '/posts'

    context 'with parameters' do
      let(:app_capturing_parameters) do
        @holder = holder = [] 

        app = Class.new(Dain::Application)
        app.route(path, :get)
          .do_any { holder[0] = request.params }
        app
      end

      def app
        app_capturing_parameters 
      end

      before do
        get real_path
      end

      subject(:request_params) do
        @holder[0]
      end 

      describe 'single part param' do
        context 'with name' do
          let(:path) { '/users/:name' }
          let(:real_path) { '/users/foo' }

          it { expect(last_response).to be_ok }
          it { expect(request_params).to eq('name' => 'foo') }
        end

        context 'without name' do
          let(:path) { '/users/:' }
          let(:real_path) { '/users/foo' }

          it { expect(last_response).to be_ok }
          it { expect(request_params).to be_empty }
        end
      end

      describe '通配符参数' do
        shared_examples '用带前缀的方式验证通配符参数' do
          context 'with name' do
            let(:path) { "#{prefix}/*name" }

            context 'one path part' do
              let(:real_path) { "#{prefix}/foo" }

              it { expect(last_response).to be_ok }
              it { expect(request_params).to eq('name' => 'foo') }
            end

            context 'multiple path parts' do
              let(:real_path) { "#{prefix}/foo/bar" }

              it { expect(last_response).to be_ok }
              it { expect(request_params).to eq('name' => 'foo/bar') }
            end
          end

          context 'without name' do
            let(:path) { "#{prefix}/*" }

            context 'one path part' do
              let(:real_path) { "#{prefix}/foo" }

              it { expect(last_response).to be_ok }
              it { expect(request_params).to be_empty }
            end

            context 'multiple path parts' do
              let(:real_path) { "#{prefix}/foo/bar" }

              it { expect(last_response).to be_ok }
              it { expect(request_params).to be_empty }
            end
          end
        end

        context '匹配完整的路径' do
          let(:prefix) { '' } # It generates `/*` and `/*name`

          include_examples '用带前缀的方式验证通配符参数'
        end

        context '匹配剩余的路径' do
          let(:prefix) { '/prefix' } # It generates '/prefix/*` and `/prefix/*name`

          include_examples '用带前缀的方式验证通配符参数'
        end

        context '在模块内定义' do
          def app
            app = Class.new(Dain::Application)
            app.apply app_capturing_parameters
            app
          end

          context 'defining in full path' do
            let(:prefix) { '' } # It generates `/*` and `/*name`

            include_examples '用带前缀的方式验证通配符参数'
          end

          context 'defining in remaining path parts' do
            let(:prefix) { '/prefix' } # It generates '/prefix/*` and `/prefix/*name`

            include_examples '用带前缀的方式验证通配符参数'
          end
        end
      end
    end
  end

  describe 'missing matched routes' do
    include_examples 'missing matching route', :post, '/posts'
    include_examples 'missing matching route', :get, '/known'
  end

  describe '嵌套子路由' do
    context '子路由内定义方法' do
      def app
        @holder = []
        the_holder = @holder

        app = Class.new(Dain::Application)
        app.route('/books')
          .do_any { 
            @resource = 'books'
          }
            .nesting do |route|
              route.method(:get)
                .do_any { the_holder[0] = 'get ' + @resource }

              route.method(:post)
                .do_any { the_holder[1] = 'post ' + @resource }
            end
          app
      end

      it '匹配子路由' do
        get '/books'

        expect(@holder[0]).to eq('get books')
      end

      it '不匹配子路由' do
        expect{ 
          put '/books' 
        }.to raise_error(Dain::Errors::NoMatchingRoute)
      end

      describe '嵌套路由是如何处理参数的' do
        def app
          holder = @holder = []

          app = Class.new(Dain::Application)

          app.route('/request')
             .params {
               param :foo, type: 'string'
             }
             .do_any {
               # excution 相同
               holder[0] = params
             }
            .nesting { |route|
              route.method(:post)
                   .params {
                     param :bar, type: 'string'
                   }
                   .do_any {
                     # excution 相同
                     holder[1] = params
                   }
            }

          app
        end

        it '分别接受两个参数' do
          post('/request', JSON.generate(foo: 'foo', bar: 'bar'), { 'CONTENT_TYPE' => 'application/json' })

          expect(@holder[0]).to eq({ foo: 'foo' })
          expect(@holder[1]).to eq({ bar: 'bar' })
        end
      end
    end

    context '子路由内定义路径' do
      def app
        @holder = holder = []

        app = Class.new(Dain::Application)
        app.route('/foo/*')
          .do_any { @resource = 'books' }
          .nesting do |route|
            route
              .method(:get, '/foo/bar')
              .do_any { holder[0] = 'matched' }
          end
        app
      end

      it '匹配父路由加子路由' do
        get '/foo/bar'

        expect(last_response).to be_ok
      end
    end
  end
end
