source 'https://gems.ruby-china.com/'

# Specify your gem's dependencies in xxx.gemspec
gemspec

gem "rake", "~> 12.0"
gem 'i18n'
gem 'hash_to_struct'

group :test do
  gem 'rspec'
  gem 'rack-test'
  gem 'grape-entity'
end

group :test, :development do
  gem 'rack'
  gem 'pry-byebug'
end
