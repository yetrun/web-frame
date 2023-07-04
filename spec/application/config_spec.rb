# frozen_string_literal: true

require 'spec_helper'

describe 'config' do
  include Rack::Test::Methods

  describe '设置默认的 scope' do
    before do
      Meta.config.default_locked_scope = 'foo'
    end

    after do
      Meta.config.default_locked_scope = nil
    end

    def app
      entity = Class.new(Meta::Entity) do
        property :foo, scope: 'foo'
        property :bar, scope: 'bar'
      end

      holder = @holder = []
      Class.new(Meta::Application) do
        post '/request' do
          request_body ref: entity
          status 200, ref: entity
          action do
            holder[0] = params
            response.status = 200
            render 'foo' => 'foo', 'bar' => 'bar'
          end
        end
      end
    end

    it '锁定为默认的 scope' do
      # TODO: 使用元数据来测试更简单
      post('/request', JSON.generate('foo' => 'foo', 'bar' => 'bar'), { 'CONTENT_TYPE' => 'application/json' })
      expect(@holder[0]).to eq(foo: 'foo')
      expect(JSON.parse(last_response.body)).to eq('foo' => 'foo')
    end

    # config.render_type_conversion 和 config.render_validation 的测试见文件 spec/application/config_spec.rb
  end
end
