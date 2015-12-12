# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'unicorn/standby/version'

Gem::Specification.new do |spec|
  spec.name          = "unicorn-standby"
  spec.version       = Unicorn::Standby::VERSION
  spec.authors       = ["Tsukasa OISHI"]
  spec.email         = ["tsukasa.oishi@gmail.com"]

  spec.summary       = %q{Unicorn Standby to standby to reach the request}
  spec.description   = %q{Unicorn Standby to standby to reach the request}
  spec.homepage      = "https://github.com/tsukasaoishi/unicorn-standby"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "unicorn", ">= 4.8.0", "< 5.1.0"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest"
end
