# frozen_string_literal: true

require_relative 'type_converter'
require_relative 'validators'
require_relative '../grape_entity_helper'
require_relative '../json_schema/schemas'

module Entities
  BaseScope = BaseSchema
  ObjectScope = ObjectSchema
  ArrayScope = ArraySchema
end
