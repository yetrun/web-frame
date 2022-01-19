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

      def app
        the_holder = holder

        app = Class.new(Application)

        app.route(path, :get)
          .do_any { the_holder[:params] = request.params }

        app
      end

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
        shared_examples 'defining glob params' do |options = {}|
          prefix = options[:prefix] || ''

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

        context 'defining in remaining path parts' do
          include_examples 'defining glob params'
        end

        context 'defining in full path' do
          include_examples 'defining glob params', prefix: '/users'
        end
      end
    end
  end

  describe 'missing matched routes' do
    include_examples 'missing matching route', :post, '/posts'
    include_examples 'missing matching route', :get, '/known'
  end
end
