# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/swagger_doc'
require 'json'
require 'grape-entity'

describe 'Dain::SwaggerDocUtil.generate' do
  subject { Dain::SwaggerDocUtil.generate(app) }

  describe 'generating tags documentation' do
    let(:app) do
      app = Class.new(Dain::Application)

      app.route('/users', :get)
        .tags(['users', 'user'])

      app
    end

    it {
      expect(subject[:paths]['/users'][:get][:tags]).to eq(['users', 'user'])
    }
  end
end
