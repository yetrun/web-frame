# frozen_string_literal: true

require_relative '../errors'
require_relative 'validators'
require_relative '../grape_entity_helper'
require_relative '../json_schema/schemas'

module Entities
  BaseScope = JsonSchema::BaseSchema
  ObjectScope = JsonSchema::ObjectSchema
  ArrayScope = JsonSchema::ArraySchema
end
