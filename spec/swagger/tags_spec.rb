# frozen_string_literal: true

require 'spec_helper'
require 'json'
require 'grape-entity'

describe 'Meta::SwaggerDocUtil.generate' do
  subject { Meta::SwaggerDocUtil.generate(app) }

  describe 'generating tags documentation' do
    let(:app) do
      app = Class.new(Meta::Application)

      app.route('/users', :get)
        .tags(['users', 'user'])

      app
    end

    it {
      expect(subject[:paths]['/users'][:get][:tags]).to eq(['users', 'user'])
    }
  end
end
