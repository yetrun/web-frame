require 'pathname'
require 'i18n'
require "i18n/backend/fallbacks"

I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
I18n.fallbacks.map(:'zh-CN' => [:zh, :en])

I18n.load_path << Pathname.new(__dir__).join('../config/locales/zh-CN.yml')
