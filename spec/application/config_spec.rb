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

    xit '锁定为默认的 scope' do
      post('/request', JSON.generate('foo' => 'foo', 'bar' => 'bar'), { 'CONTENT_TYPE' => 'application/json' })
      expect(@holder[0]).to eq(foo: 'foo')
      expect(JSON.parse(last_response.body)).to eq('foo' => 'foo')
    end
  end

  describe 'json_schema_user_options' do
    describe '综合 common、param、render 三个阶段的配置' do
      before do
        Meta.config.json_schema_user_options = { type_conversion: false, validation: false }
        Meta.config.json_schema_param_stage_user_options = { type_conversion: true, validation: false }
        Meta.config.json_schema_render_stage_user_options = { type_conversion: false, validation: true }
      end

      after do
        Meta.config.json_schema_user_options = {}
        Meta.config.json_schema_param_stage_user_options = {}
        Meta.config.json_schema_render_stage_user_options = {}
      end

      def app
        Class.new(Meta::Application) do
          post '/parse_params' do
            request_body do
              param :foo, type: 'integer', required: true
            end
            action do
              response.body = [JSON.generate(params)]
            end
          end

          post '/render_entity' do
            status 200 do
              expose :foo, type: 'integer', required: true
            end
            action do
              render :foo => params(:raw)['foo']
            end
          end
        end
      end

      describe '解析参数行为' do
        it '参数应用类型转换' do
          expect {
            post '/parse_params', JSON.generate(foo: 'foo'), { 'CONTENT_TYPE' => 'application/json' }
          }.to raise_error(Meta::Errors::ParameterInvalid)
        end

        it '参数没有应用数据验证' do
          expect {
            post '/parse_params', JSON.generate(foo: nil), { 'CONTENT_TYPE' => 'application/json' }
          }.not_to raise_error
        end
      end

      describe '渲染实体行为' do
        it '渲染没有应用类型转换' do
          expect {
            post '/render_entity', JSON.generate(foo: 'foo'), { 'CONTENT_TYPE' => 'application/json' }
          }.not_to raise_error
        end

        it '渲染应用数据验证' do
          expect {
            post '/render_entity', JSON.generate(foo: nil), { 'CONTENT_TYPE' => 'application/json' }
          }.to raise_error(Meta::Errors::RenderingInvalid)
        end
      end
    end

    describe '禁止渲染类型转换' do
      before do
        Meta.config.json_schema_render_stage_user_options = { type_conversion: false }
      end

      after do
        Meta.config.json_schema_render_stage_user_options = { type_conversion: true }
      end

      let(:object) do
        object = Object.new
        def object.bar; 'bar'; end
        def object.baz; 'baz'; end
        object
      end

      let(:array) do
        array = Object.new
        def array.to_a; [1, 2, 3]; end
        array
      end

      def app
        the_object = object
        the_array = array

        Class.new(Meta::Application) do
          post '/render_object' do
            status 200 do
              expose :foo do
                expose :bar
                expose :baz
              end
            end
            action do
              render :foo, the_object
            end
          end

          post '/render_array' do
            status 200 do
              expose :foo, type: 'array'
            end
            action do
              render :foo, the_array
            end
          end
        end
      end

      it '不影响自定义对象类型的渲染' do
        post '/render_object'
        expect(JSON.parse(last_response.body)).to eq('foo' => { 'bar' => 'bar', 'baz' => 'baz' })
      end

      it '不影响自定义数组类型的渲染' do
        post '/render_array'
        expect(JSON.parse(last_response.body)).to eq('foo' => [1, 2, 3])
      end
    end
  end
end
