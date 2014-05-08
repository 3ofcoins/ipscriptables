# -*- mode: ruby; coding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ipscriptables/version'

Gem::Specification.new do |spec|
  spec.name          = 'ipscriptables'
  spec.version       = IPScriptables::VERSION
  spec.authors       = ['Maciej Pasternacki']
  spec.email         = ['maciej@3ofcoins.net']
  spec.description   = 'Ruby-driven IPTables'
  spec.summary       = 'Ruby-driven IPTables'
  spec.homepage      = 'https://github.com/3ofcoins/ipscriptables/'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(/^bin\//) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(/^(test|spec|features)\//)
  spec.require_paths = ['lib']

  spec.add_dependency 'docile'
  spec.add_dependency 'hashie'
  spec.add_dependency 'systemu'
  spec.add_dependency 'ohai'
  spec.add_dependency 'sigar'   # for OHAI's network_listeners plugin
  spec.add_dependency 'ipaddr_extensions' # for OHAI's ip_scopes plugin
  spec.add_dependency 'diffy'
  spec.add_dependency 'clamp'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'mocha'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'rake', '~> 10.1'
  spec.add_development_dependency 'wrong', '~> 0.7'
  spec.add_development_dependency 'fauxhai'
  spec.add_development_dependency 'rubocop'
end
