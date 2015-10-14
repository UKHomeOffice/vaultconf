# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vaultconf/version'

Gem::Specification.new do |spec|
  spec.name          = "vaultconf"
  spec.version       = Vaultconf::VERSION
  spec.authors       = ["Tim Gent"]
  spec.email         = ["tim.gent@gmail.com"]

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com' to prevent pushes to rubygems.org, or delete to allow pushes to any server."
  end

  spec.summary       = %q{TODO: Write a short summary, because Rubygems requires one.}
  spec.description   = %q{TODO: Write a longer description or delete this line.}
  spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.license       = "apache"

  # spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency('rdoc')
  spec.add_development_dependency('aruba')
  spec.add_development_dependency('rake')
  spec.add_dependency('methadone', '~> 1.9.1')
  spec.add_dependency('vault','~> 0.1.5')
  spec.add_dependency('curb','~> 0.8.8')
  spec.add_dependency('webmock','~> 1.21.0')
  spec.add_dependency('json','~> 1.8.3')
  spec.add_development_dependency('test-unit')
  spec.add_development_dependency('mocha', '~> 1.1.0')
  spec.add_development_dependency('fakefs', '~> 0.6.7')
end
