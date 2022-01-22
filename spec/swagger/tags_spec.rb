# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/swagger_doc'
require 'json'
require 'grape-entity'

describe 'SwaggerDocUtil.generate' do
  subject { SwaggerDocUtil.generate(app) }

  describe 'generating tags documentation' do
    let(:app) do
      app = Class.new(Application)

      app.route('/users', :get)
        .tags(['users', 'user'])

      app
    end

    it {
      expect(subject[:paths]['/users'][:get][:tags]).to eq(['users', 'user'])
    }
  end
end
