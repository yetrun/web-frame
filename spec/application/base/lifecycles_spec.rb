# frozen_string_literal: true

require 'spec_helper'

describe Application, 'lifecycles' do
  before { @holder = [] }

  def app
    build_app
  end

  def build_app
    holder = @holder

    app = Class.new(Application)

    app.before { holder << 'before one' }
    app.before { holder << 'before two' }

    app.after { holder << 'after one' }
    app.after { holder << 'after two' }

    app.route('/users', :get)
      .authorize { true }
      .do_any { holder << 'get users' }

    app.route('/posts', :get)
      .authorize { false }
      .do_any { holder << 'get posts' }

    app
  end

  it 'executes lifecycles' do
    get '/users'

    expect(last_response.status).to eq 200
    expect(@holder).to eq ['before one', 'before two', 'get users', 'after one', 'after two']
  end

  context 'when defining lifecycles in inner module' do
    def app
      app = Class.new(Application)

      app.apply build_app

      app
    end

    it 'executes inner lifecycles' do
      get '/users'

      expect(last_response.status).to eq 200
      expect(@holder).to eq ['before one', 'before two', 'get users', 'after one', 'after two']
    end
  end

  context 'when defining lifecycles in both outer module and inner module' do
    def app
      holder = @holder

      app = Class.new(Application)

      app.apply build_app

      app.before { holder << 'outer before' }
      app.after { holder << 'outer after' }

      app
    end

    it 'executes both outer lifecycles and inner lifecycles' do
      get '/users'

      expect(last_response.status).to eq 200
      expect(@holder).to eq ['outer before', 'before one', 'before two', 'get users', 'after one', 'after two', 'outer after']
    end
  end
end
