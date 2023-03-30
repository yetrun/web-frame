# frozen_string_literal: true

require 'spec_helper'
require 'json'
require 'grape-entity'

describe 'Meta::SwaggerDocUtil.generate' do
  subject { Meta::SwaggerDocUtil.generate(app) }

  describe 'generating tags documentation' do
    let(:app) do
      Class.new(Meta::Application) do
        get '/users' do
          tags ['users', 'user']
        end
      end
    end

    it {
      expect(subject[:paths]['/users'][:get][:tags]).to eq(['users', 'user'])
    }
  end
end
