# frozen_string_literal: true

module Meta
  class Config
    attr_accessor :render_validation, :render_type_conversion

    def initialize
      @render_type_conversion = true
      @render_validation = true
    end
  end

  @config = Config.new
  class << self
    attr_reader :config
  end
end
