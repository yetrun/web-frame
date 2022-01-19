require 'spec_helper'

describe Execution do
  include Rack::Test::Methods

  before { @holder = {} }

  def app
    holder = @holder

    app = Class.new(Application)

    app.route('/users', :get)
      .do_any { 
        holder[:request] = request
        holder[:response] = response
      }

    app
  end

  describe '#request' do
    it 'is Rack::Request' do
      expect(@holder[:request]).is_a?(Rack::Request)
    end
  end

  describe '#response' do
    it 'is Rack::Response' do
      expect(@holder[:response]).is_a?(Rack::Response)
    end
  end
end
