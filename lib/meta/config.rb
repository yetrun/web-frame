# frozen_string_literal: true

module Meta
  class Config
    attr_accessor :default_locked_scope,
                  :json_schema_user_options,
                  :json_schema_param_stage_options,
                  :json_schema_render_stage_options

    def initialize
      @default_locked_scope = nil
      @json_schema_user_options = {}
      @json_schema_param_stage_options = {}
      @json_schema_render_stage_options = {}
    end
  end

  @config = Config.new
  class << self
    attr_reader :config
  end
end
