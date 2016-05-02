#!/usr/bin/env ruby -rubygems
# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.version            = File.read('VERSION').chomp
  gem.date               = File.mtime('VERSION').strftime('%Y-%m-%d')

  gem.name               = 'ladder-ldp'
  gem.homepage           = 'https://github.com/ladder/ladder'
  gem.license            = 'Apache-2.0'
  gem.summary            = 'An opinionated LDP server based on RDF::LDP.'
  gem.description        = 'Linked Data Platform in Ruby'

  gem.authors            = ['MJ Suhonos']
  gem.email              = 'mj@suhonos.ca'

  gem.platform           = Gem::Platform::RUBY
  gem.files              = %w(AUTHORS README.md VERSION) +
                           Dir.glob('lib/**/*.rb') + Dir.glob('app/**/*.rb')
  gem.bindir             = %q(bin)
  gem.executables        = %w(ladder)
  gem.default_executable = gem.executables.first
  gem.require_paths      = %w(lib app)
  gem.has_rdoc           = false

  gem.required_ruby_version      = '>= 2.0.0'
  gem.requirements               = []

  gem.add_runtime_dependency 'rdf-ldp'
  gem.add_runtime_dependency 'rdf-mongo'
  gem.add_runtime_dependency 'elasticsearch-persistence'
  gem.add_runtime_dependency 'activejob'

  gem.add_development_dependency 'pry'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'yard'
  gem.add_development_dependency 'rack-test'
  gem.add_development_dependency 'timecop'

  gem.post_install_message       = nil
end