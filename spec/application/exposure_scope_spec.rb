require_relative '../test_helper'
require 'grape-entity'

describe ExposureScope do
  include Rack::Test::Methods

  subject { ExposureScope.new }

  let(:generated_json) do
    json = subject.generate_json(Object.new)
    JSON.parse(json)
  end

  let(:invoking_as_json) do
    obj = Object.new
    def obj.as_json; 'object invokes `as_json` method' end

    obj
  end

  let(:user_object) do
    user = Object.new
    def user.name; 'Jim' end
    def user.age; 18 end

    user
  end

  let(:user_entity_class) do
    Class.new(Grape::Entity) do
      expose :name, :age
    end
  end

  describe 'exposing values directly' do
    before do
      the_object_invoking_as_json = invoking_as_json
      the_user_object = user_object

      subject.expose(:hash) { { a: 1, b: 2 } }                          # a hash
      subject.expose(:primitive) { 'a value' }                          # primitive value
      subject.expose(:invoking_as_json) { the_object_invoking_as_json } # a object invoking `as_json` method
      subject.expose { { c: 3, d: 4 } }                                 # merged into above exposes
    end

    it {
      expect(generated_json).to eq(
        'hash' => { 'a' => 1, 'b' => 2 },
        'primitive' => 'a value',
        'invoking_as_json' => invoking_as_json.as_json,
        'c' => 3, 'd' => 4
      )
    }
  end

  describe 'exposing with entity class' do
    before do
      the_user_object = user_object

      subject.expose(:user, user_entity_class) { the_user_object }    # generate using entity class
      subject.expose(user_entity_class) { the_user_object }           # merged into above expose
    end

    it {
      expect(generated_json).to eq(
        'user' => { 'name' => user_object.name, 'age' => user_object.age },
        'name' => user_object.name, 'age' => user_object.age,
      )
    }
  end
end
