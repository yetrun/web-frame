require 'bundler/setup'
require "rack/test"
require_relative '../lib/meta/api'

I18n.locale = :'zh-CN'

RSpec.configure do |config|
  config.include(Rack::Test::Methods)
end

# require 'pry'
