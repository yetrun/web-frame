require 'rack'

describe Rack::Response do
  subject { Rack::Response.new }

  it 'gets body as empty array' do
    expect(subject.body).to eq []
  end

  it 'sets status' do
    subject.status = 201
    expect(subject.status).to eq 201
  end

  it 'sets body' do
    subject.body = 'Hello, world!'
    expect(subject.body).to eq 'Hello, world!'
  end

  it 'sets headers' do
    subject.headers['Content-Type'] = 'application/xml'
    expect(subject.headers).to eq('Content-Type' => 'application/xml')
  end
end
