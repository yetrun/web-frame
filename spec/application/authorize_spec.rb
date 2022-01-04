require_relative '../test_helper'

describe Application, '.authorize' do
  before { @holder = {} }

  def app
    holder = @holder

    app = Class.new(Application)

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
    get '/forbid'

    expect(last_response.status).to eq 403
    expect(@holder).to be_empty
  end
end
