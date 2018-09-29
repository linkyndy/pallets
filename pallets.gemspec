# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pallets/version'

Gem::Specification.new do |spec|
  spec.name          = "pallets"
  spec.version       = Pallets::VERSION
  spec.authors       = ["Andrei Horak"]
  spec.email         = ["linkyndy@gmail.com"]

  spec.summary       = 'Toy workflow engine, written in Ruby'
  spec.description   = 'Toy workflow engine, written in Ruby'
  spec.homepage      = 'https://github.com/linkyndy/pallets'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = ["pallets"]
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport"
  spec.add_dependency "redis"
  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "timecop"
  spec.add_development_dependency "fuubar"
end
