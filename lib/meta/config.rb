# frozen_string_literal: true

require 'hash_to_struct'

module Meta
  DEFAULT_OPTIONS = {
    default_locked_scope: nil,
    json_schema_user_options: {},
    json_schema_param_stage_user_options: {},
    json_schema_render_stage_user_options: {}
  }

  class << self
    attr_reader :config

    def initialize_configuration(*options_list)
      final_options = options_list.reduce(DEFAULT_OPTIONS, :deep_merge)
      @config = HashToStruct.struct(final_options)
    end
  end
end
Meta.initialize_configuration
