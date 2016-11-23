#!/usr/bin/env ruby -rubygems
# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.version            = File.read('VERSION').chomp
  gem.date               = File.mtime('VERSION').strftime('%Y-%m-%d')

  gem.name               = 'shex'
  gem.homepage           = 'http://ruby-rdf.github.com/shex'
  gem.license            = 'Unlicense'
  gem.summary            = 'Implementation of Shape Expressions (ShEx) for RDF.rb'
  gem.description        = 'Implements ShExC and ShEx JSON.'
  gem.rubyforge_project  = 'rdf'

  gem.authors            = ['Gregg Kellogg']
  gem.email              = 'public-rdf-ruby@w3.org'

  gem.platform           = Gem::Platform::RUBY
  gem.files              = %w(AUTHORS CREDITS README.md LICENSE VERSION etc/doap.ttl) + Dir.glob('lib/**/*.rb')
  gem.require_paths      = %w(lib)
  gem.extensions         = %w()
  gem.test_files         = %w()
  gem.has_rdoc           = false

  gem.required_ruby_version      = '>= 2.2.2'
  gem.requirements               = []
  gem.add_runtime_dependency     'rdf',         '~> 2.0'
  gem.add_runtime_dependency     'ebnf',        '~> 1.0', '>= 1.0.1'
  gem.add_runtime_dependency     'sxp',         '~> 1.0'
  gem.add_runtime_dependency     'sparql',      '~> 2.0'

  gem.add_development_dependency 'rdf-spec',    '~> 2.0'
  gem.add_development_dependency 'rdf-turtle',  '~> 2.0'
  gem.add_development_dependency 'rdf-xsd',     '~> 2.0'
  gem.add_development_dependency 'rspec',       '~> 3.0'
  gem.add_development_dependency 'rspec-its',   '~> 1.0'
  gem.add_development_dependency 'yard',        '~> 0.8'

  gem.post_install_message       = nil
end
