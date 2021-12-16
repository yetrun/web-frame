require "minitest/autorun"
require "rack/test"

class RackTest < Minitest::Test
  include Rack::Test::Methods

  def app
    lambda { |env| [200, {'Content-Type' => 'text/plain'}, ['All responses are OK']] }
  end

  def test_response_is_ok
    get '/'

    assert last_response.ok?
    assert_equal last_response.body, 'All responses are OK'
  end

  def set_request_headers
    header 'Accept-Charset', 'utf-8'
    get '/'

    assert last_response.ok?
    assert_equal last_response.body, 'All responses are OK'
  end

  def test_response_is_ok_for_other_paths
    get '/other_paths'

    assert last_response.ok?
    assert_equal last_response.body, 'All responses are OK'
  end

  def post_with_json
    # No assertion in this, we just demonstrate how you can post a JSON-encoded string.
    # By default, Rack::Test will use HTTP form encoding if you pass in a Hash as the
    # parameters, so make sure that `json` below is already a JSON-serialized string.
    post(uri, json, { 'CONTENT_TYPE' => 'application/json' })
  end

  def delete_with_url_params_and_body
    delete '/?foo=bar', JSON.generate('baz' => 'zot')
  end
end
