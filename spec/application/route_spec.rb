require_relative '../test_helper'
require_relative '../support/shared_examples'

describe Application, '.route' do
  include Rack::Test::Methods

  def app
    app = Class.new(Application)

    app.route('/users', :get)
    app.route('/users', :post)
    app.route('/posts', :get)

    holder = @holder
    app.route('/users/:id', :get)
      .do_any { holder[:params] = request.params }

    app
  end

  describe 'matched routes' do
    include_examples 'matching route', :get, '/users'
    include_examples 'matching route', :post, '/users'
    include_examples 'matching route', :get, '/posts'

    context 'with path parameter' do
      before { @holder = {} }

      it 'parses path parameter' do
        get '/users/1'

        expect(last_response).to be_ok

        expect(@holder[:params]).to eq('id' => '1')
      end
    end
  end

  describe 'missing matched routes' do
    include_examples 'missing matching route', :post, '/posts'
    include_examples 'missing matching route', :get, '/known'
  end
end
