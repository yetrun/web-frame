require_relative '../test_helper'

describe Application, '.rescue_error' do
  include Rack::Test::Methods

  class CuaghtError < StandardError; end
  class EscapedErros < StandardError; end

  def app
    app = Class.new(Application)

    app.rescue_error(CuaghtError) {
      response.status = 500
      response.body = ['Customized error!']
    }

    app.route('/caught', :get)
      .do_any { raise CuaghtError }

    app.route('/escaped', :get)
      .do_any { raise EscapedError }

    app
  end

  it 'catch rescued error' do
    get '/caught'

    expect(last_response.status).to eq 500
    expect(last_response.body).to eq 'Customized error!'
  end

  it 'raises not rescued error' do
    expect { get '/escaped' }.to raise_error(EscapedError)
  end

  context 'raising error in inner module' do
    class CaughtByInnerError < StandardError; end
    class CaughtByOuterError < StandardError; end
    class EscapedError < StandardError; end

    def app
      inner_app = Class.new(Application)

      inner_app.rescue_error(CaughtByInnerError) {
        response.status = 500
        response.body = ['Caught by inner module!']
      }
      inner_app.route('/caught/by_inner', :get)
        .do_any { raise CaughtByInnerError }
      inner_app.route('/caught/by_outer', :get)
        .do_any { raise CaughtByOuterError }
      inner_app.route('/escaped', :get)
        .do_any { raise EscapedError }

      app = Class.new(Application)
      app.rescue_error(CaughtByOuterError) {
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
        expect { get '/escaped' }.to raise_error(EscapedError)
      end
    end
  end

  context 'raising error again in inner module' do
    class CaughtByInnerError < StandardError; end
    class CaughtByOuterError < StandardError; end

    def app
      inner_app = Class.new(Application)

      inner_app.rescue_error(CaughtByInnerError) {
        raise CaughtByOuterError
      }
      inner_app.route('/caught', :get)
        .do_any { raise CaughtByInnerError }

      app = Class.new(Application)
      app.rescue_error(CaughtByOuterError) {
        response.status = 500
        response.body = ['Caught by outer module!']
      }
      app.apply inner_app

      app
    end

    context 'defining `resuce_from` in outer module' do
      it 'rescues' do
        get '/caught'

        expect(last_response.status).to eq 500
        expect(last_response.body).to eq 'Caught by outer module!'
      end
    end
  end
end
