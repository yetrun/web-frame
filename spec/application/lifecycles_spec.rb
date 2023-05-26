# frozen_string_literal: true

require 'spec_helper'

describe Meta::Application, 'lifecycles' do
  before { @holder = [] }

  def app
    build_app
  end

  def build_app
    holder = @holder

    app = Class.new(Meta::Application)

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
      app = Class.new(Meta::Application)

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
      inner_app = build_app

      Class.new(Meta::Application) do
        apply inner_app

        before { holder << 'outer before' }
        after { holder << 'outer after' }
      end
    end

    it 'executes both outer lifecycles and inner lifecycles' do
      get '/users'

      expect(last_response.status).to eq 200
      expect(@holder).to eq ['outer before', 'before one', 'before two', 'get users', 'after one', 'after two', 'outer after']
    end
  end

  context '加入 around 回调函数' do
    def app
      holder = @holder
      Class.new(Meta::Application) do
        before { holder << 1 }
        before { holder << 2 }

        around do |next_action|
          holder << 3
          next_action.execute(self)
          holder << 11
        end

        after { holder << 6 }
        after { holder << 7 }

        around do |next_action|
          holder << 4
          next_action.execute(self)
          holder << 10
        end

        after { holder << 8 }
        after { holder << 9 }

        get('/users').action { holder << 5 }
      end
    end

    it 'executes lifecycles' do
      get '/users'

      expect(last_response.status).to eq 200
      expect(@holder).to eq [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
    end
  end
end
