lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "enu/version"

Gem::Specification.new do |spec|
  spec.name          = "enu"
  spec.version       = Enu::VERSION
  spec.authors       = ["Alex Musayev"]
  spec.email         = ["alex.musayev@gmail.com"]
  spec.summary       = "Missing enum type for Ruby and Rails"
  spec.description   = "See the readme file for feature details and usage examples."
  spec.homepage      = "https://github.com/dreikanter/enu"
  spec.license       = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/dreikanter/enu/blob/master/CHANGELOG.md"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end

  spec.required_ruby_version = ">= 2.3.0"
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "guard", "~> 2.15"
  spec.add_development_dependency "guard-minitest", "~> 2.4", ">= 2.4.6"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "minitest-reporters", "~> 1.3", ">= 1.3.6"
  spec.add_development_dependency "pry", "~> 0.12.2"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rb-readline", "~> 0.5.5"
  spec.add_development_dependency "rubocop", "~> 0.72.0"
  spec.add_development_dependency "simplecov", "~> 0.17"
  spec.add_development_dependency "standard", "~> 0.1.0"
end
