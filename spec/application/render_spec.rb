# frozen_string_literal: true

require 'spec_helper'

describe 'render' do
  include Rack::Test::Methods

  context '完整渲染' do
    def app
      app = Class.new(Meta::Application)

      app.route('/request', :post)
        .do_any {
          render('user' => { 'name' => 'Jim', 'age' => 18 })
        }
        .if_status(200) {
          property :user do
            property :name
            property :age
          end
        }

      app
    end

    specify do
      post('/request')

      response_json = JSON.parse(last_response.body)
      expect(response_json['user']).to eq('name' => 'Jim', 'age' => 18)
    end
  end

  context '带符号键名' do
    context '渲染正确的键名' do
      def app
        app = Class.new(Meta::Application)

        app.route('/request', :post)
          .do_any {
            render(:user, { 'name' => 'Jim', 'age' => 18 })
          }
          .if_status(200) {
            property :user do
              property :name
              property :age
            end
          }

        app
      end

      specify do
        post('/request')

        response_json = JSON.parse(last_response.body)
        expect(response_json['user']).to eq('name' => 'Jim', 'age' => 18)
      end
    end

    context '渲染错误的键名' do
      def app
        app = Class.new(Meta::Application)

        app.route('/request', :post)
          .do_any {
            render(:user2, { 'name' => 'Jim', 'age' => 18 })
          }
          .if_status(200) {
            property :user do
              property :name
              property :age
            end
          }

        app
      end

      specify do
        expect {
          post('/request')
        }.to raise_error(Meta::Errors::RenderingError, /user2/)
      end
    end
  end
end
