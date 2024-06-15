require 'bundler/setup'
require "rack/test"
require 'pry'
require_relative '../lib/meta/api'
require_relative 'support/openapi_helpers'

I18n.locale = :'zh-CN'

RSpec.configure do |config|
  config.include(Rack::Test::Methods)
  config.include(OpenAPIHelpers)
end

RSpec::Matchers.define :be_valid_openapi_document do
  require 'json_schemer'

  match do |doc|
    document = JSON.parse(JSON.generate(doc))
    @schema = JSONSchemer.openapi(document)
    @schema.valid?
  end

  failure_message do |doc|
    <<~FAILURE_MESSAGE
      OpenAPI 文档验证失败：
      - 原文档：#{doc}
      - 错误信息：#{@schema.validate.to_a}
    FAILURE_MESSAGE
  end

  failure_message_when_negated do |doc|
    <<~FAILURE_MESSAGE
      期望不是一份合法的 OpenAPI 文档
      - 原文档：#{doc}
    FAILURE_MESSAGE
  end
end
