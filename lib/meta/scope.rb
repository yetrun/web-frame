# frozen_string_literal: true

require_relative 'json_schema/scopes'

Meta::Scope = Meta::JsonSchema::Scopes::Factory
