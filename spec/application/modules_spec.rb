require 'spec_helper'
require 'support/shared_examples'

describe Meta::Application, '.apply' do
  include Rack::Test::Methods

  def app
    users_app = Class.new(Meta::Application)
    users_app.route('/users', :get)

    posts_app = Class.new(Meta::Application)
    posts_app.route('/posts', :get)

    app = Class.new(Meta::Application)
    app.apply users_app
    app.apply posts_app

    app
  end

  describe 'matching the sub routes' do
    include_examples 'matching route', :get, '/users'
    include_examples 'matching route', :get, '/posts'
  end

  describe 'missing to match any routes' do
    include_examples 'missing matching route', :post, '/users'
    include_examples 'missing matching route', :get, '/known'
  end
end
