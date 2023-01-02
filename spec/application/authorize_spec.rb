require 'spec_helper'

describe Meta::Application, '.authorize' do
  before { @holder = {} }

  def app
    holder = @holder

    app = Class.new(Meta::Application)

    app.route('/permit', :get)
      .authorize { true }
      .do_any { holder[:action] = 'permitted'}

    app.route('/forbid', :get)
      .authorize { false }
      .do_any { holder[:action] = 'permitted' }

    app
  end

  it 'permits when authorize true' do
    get '/permit'

    expect(last_response.status).to eq 200
    expect(@holder[:action]).to eq 'permitted'
  end

  it 'forbids when authorize false' do
    expect {
      get '/forbid'
    }.to raise_error(Meta::Errors::NotAuthorized)
  end
end
