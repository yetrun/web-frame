require "rack/test"
require_relative '../lib/application'

RSpec.configure do |config|
  config.include(Rack::Test::Methods)
end

require 'pry'
