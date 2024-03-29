require_relative "lib/aufgaben/version"

Gem::Specification.new do |spec|
  spec.name          = "aufgaben"
  spec.version       = Aufgaben::VERSION
  spec.authors       = ["Masafumi Koba"]
  spec.email         = ["ybiquitous@gmail.com"]
  spec.license       = "MIT"

  spec.summary       = "The collection of useful Rake tasks."
  spec.description   = "Aufgaben provides a collection of practical Rake tasks for automation."
  spec.homepage      = "https://github.com/ybiquitous/aufgaben"

  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files         = Dir["CHANGELOG.md", "LICENSE", "README.md", "exe/*", "lib/**/*.{rb,json}"]
  spec.bindir        = "exe"
  spec.executables   = []
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
end
