require 'bundler/setup'
require "rack/test"
require_relative '../lib/application'
require_relative '../lib/load_i18n'

I18n.locale = :'zh-CN'

RSpec.configure do |config|
  config.include(Rack::Test::Methods)
end

require 'pry'
