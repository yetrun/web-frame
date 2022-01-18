shared_examples 'matching route' do |method, path|
  it "matches when request #{method} #{path}" do
    send method, path

    expect(last_response).to be_ok
  end
end

shared_examples 'missing matching route' do |method, path|
  it "raises error when request #{method} #{path}" do
    expect {
      send method, path
    }.to raise_error(Errors::NoMatchingRoute)
  end
end
