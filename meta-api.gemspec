Gem::Specification.new do |spec|
  spec.name          = "meta-api"
  spec.version       = "0.0.2"
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

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ["lib"]
end
