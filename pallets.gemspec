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
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = ["pallets"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.3'

  spec.add_dependency "redis"
  spec.add_dependency "msgpack"
end
