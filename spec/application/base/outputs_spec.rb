require 'spec_helper'

describe Application, '.outputs' do
  before { @holder = {} }

  def app
    holder = @holder

    app = Class.new(Application)

    app.route('/resource', :get)
      .outputs do
        output(:foo) { { a: 1, b: 2 } }
        output(:bar) { { c: 3, d: 4 } }
      end

    app
  end

  it 'generates json response content' do
    get '/resource'

    expect(last_response).to be_ok
    expect(JSON.parse(last_response.body)).to eq(
      'foo' => { 'a' => 1, 'b' => 2 },
      'bar' => { 'c' => 3, 'd' => 4 },
    )
  end
end
