# frozen_string_literal: true

require 'spec_helper'

describe 'render' do
  include Rack::Test::Methods

  describe '调用方式' do
    def app
      the_render_call = render_call

      Class.new(Meta::Application) do
        post '/request' do
          status 200 do
            property :user do
              property :name
              property :age
            end
            property :status, type: 'integer'
          end
          action &the_render_call
        end
      end
    end

    context '渲染完整的对象' do
      let(:render_call) do
        proc { render 'user' => { 'name' => 'Jim', 'age' => 18 } }
      end

      it '渲染出完整的 JSON 对象' do
        post('/request')

        response_json = JSON.parse(last_response.body)
        expect(response_json['user']).to eq('name' => 'Jim', 'age' => 18)
      end
    end

    context '渲染时带符号键名' do
      context '渲染正确的键名' do
        let(:render_call) do
          proc { render(:user, { 'name' => 'Jim', 'age' => 18 }) }
        end

        it '正确渲染出结果' do
          post('/request')

          response_json = JSON.parse(last_response.body)
          expect(response_json['user']).to eq('name' => 'Jim', 'age' => 18)
        end
      end

      context '渲染的键名带错误提示消息' do
        let(:render_call) do
          proc {
            render(:user, 'a string')
            render(:status, "success")
          }
        end

        it '正确渲染出结果' do
          expect {
            post('/request')
          }.to raise_error(Meta::Errors::RenderingInvalid) do |e|
            expect(e.errors.keys).to include(:user, :status)
          end
        end
      end

      context '渲染错误的键名' do
        let(:render_call) do
          proc { render(:wrong_key, { 'name' => 'Jim', 'age' => 18 }) }
        end

        it '报错' do
          expect {
            post('/request')
          }.to raise_error(Meta::Errors::RenderingError, /wrong_key/)
        end
      end
    end
  end

  describe '关闭类型转换' do
    def app
      Class.new(Meta::Application) do
        post '/request' do
          status 200 do
            property :foo, type: 'number'
          end
          action do
            render 'foo' => 'xxx'
          end
        end
      end
    end

    it '默认情况做类型转换，遇到类型转换失败时报错' do
      expect {
        post('/request')
      }.to raise_error(Meta::Errors::RenderingInvalid, /foo/)
    end

    it '关闭类型转换后执行不报错' do
      Meta.config.render_type_conversion = false
      expect { post('/request') }.not_to raise_error
      Meta.config.render_type_conversion = true
    end
  end

  describe '关闭验证器' do
    def app
      Class.new(Meta::Application) do
        post '/request' do
          status 200 do
            property :foo, format: /\d\d\d\d/
          end
          action do
            render 'foo' => '333'
          end
        end
      end
    end

    it '默认情况执行验证器，遇到验证失败时报错' do
      expect {
        post('/request')
      }.to raise_error(Meta::Errors::RenderingInvalid, /foo/)
    end

    it '关闭验证器后执行不报错' do
      Meta.config.render_validation = false
      expect { post('/request') }.not_to raise_error
      Meta.config.render_validation = true
    end
  end

  describe '传递用户数据' do
    def app
      Class.new(Meta::Application) do
        post '/request' do
          status 200 do
            property :foo, value: Proc.new { |parent, user_data| parent['foo'] + user_data[:bar] }
          end
          action do
            render({ 'foo' => '333' }, user_data: { bar: 'bar' })
          end
        end
      end
    end

    it '默认情况执行验证器，遇到验证失败时报错' do
      post('/request')
      expect(JSON.parse(last_response.body)['foo']).to eq('333bar')
    end
  end
end
