Gem::Specification.new do |spec|
  spec.name          = "meta-api"
  spec.version       = "0.0.9"
  spec.authors       = ["yetrun"]
  spec.email         = ["yetrun@foxmail.com"]

  spec.summary       = "一个 Web API 框架"
  spec.description   = "一个 Web API 框架，该框架采用定义元信息的方式编写 API，并同步生成 API 文档"
  spec.homepage      = "https://github.com/yetrun/web-frame"
  spec.license       = "LGPL-2.1"
  spec.required_ruby_version = Gem::Requirement.new(">= 3.0.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/yetrun/web-frame.git"

  spec.add_dependency "hash_to_struct", "~> 1.0.0"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob("{config,lib}/{.rb,/**/*}", File::FNM_DOTMATCH).reject {|f| File.directory?(f) }
  spec.files += %w[CHANGELOG.md LICENSE.txt meta-api.gemspec]

  spec.require_paths = ["lib"]
end
