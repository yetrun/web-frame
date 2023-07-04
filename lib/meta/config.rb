# frozen_string_literal: true

module Meta
  class Config
    attr_accessor :render_validation, :render_type_conversion, :default_locked_scope, :handle_extra_properties

    def initialize
      @render_type_conversion = true
      @render_validation = true
      @default_locked_scope = nil
      @handle_extra_properties = :ignore
    end
  end

  @config = Config.new
  class << self
    attr_reader :config
  end
end
