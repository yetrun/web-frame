require 'spec_helper'
require 'support/shared_examples'

describe Meta::Application, '.route' do
  include Rack::Test::Methods

  def app
    app = Class.new(Meta::Application)

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

        app = Class.new(Meta::Application)
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
            app = Class.new(Meta::Application)
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
end
