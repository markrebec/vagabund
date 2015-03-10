# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vagabund/version'

Gem::Specification.new do |spec|
  spec.name          = "vagabund"
  spec.version       = Vagabund::VERSION
  spec.authors       = ["Mark Rebec"]
  spec.email         = ["mark@markrebec.com"]
  spec.summary       = "Vagrant plugin for provisioning users, configs, packages, projects and more."
  spec.description   = "Vagrant plugin providing automatic config management, git operations and the ability to checkout projects and manage services."
  spec.homepage      = "https://github.com/markrebec/vagabund"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "dotenv"
end
