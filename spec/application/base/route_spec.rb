require 'spec_helper'
require 'support/shared_examples'

describe Application, '.route' do
  include Rack::Test::Methods

  def app
    app = Class.new(Application)

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
      let(:holder) { {} }

      let(:base_app) do
        the_holder = holder

        app = Class.new(Application)

        app.route(path, :get)
          .do_any { the_holder[:params] = request.params }

        app
      end

      let(:app) { base_app }

      before do
        get real_path
      end

      subject(:request_params) do
        holder[:params]
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

      describe 'glob parts param' do
        shared_examples 'defining glob params' do
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

        context 'defining in full path' do
          let(:prefix) { '' } # It generates `/*` and `/*name`

          include_examples 'defining glob params'
        end

        context 'defining in remaining path parts' do
          let(:prefix) { '/prefix' } # It generates '/prefix/*` and `/prefix/*name`

          include_examples 'defining glob params'
        end

        context 'defining in modules' do
          def app
            app = Class.new(Application)
            app.apply base_app
            app
          end

          context 'defining in full path' do
            let(:prefix) { '' } # It generates `/*` and `/*name`

            include_examples 'defining glob params'
          end

          context 'defining in remaining path parts' do
            let(:prefix) { '/prefix' } # It generates '/prefix/*` and `/prefix/*name`

            include_examples 'defining glob params'
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
    def app
      @holder = []
      the_holder = @holder

      app = Class.new(Application)
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
      }.to raise_error(Errors::NoMatchingRoute)
    end
  end
end
