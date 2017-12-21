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
  gem.metadata["yard.run"] = "yri" # use "yard" to build full HTML docs.

  gem.required_ruby_version      = '>= 2.2.2'
  gem.requirements               = []
  #gem.add_runtime_dependency     'rdf',         '~> 3.0'
  #gem.add_runtime_dependency     'json-ld',     '~> 3.0'
  #gem.add_runtime_dependency     'json-ld-preloaded','~> 3.0'
  gem.add_runtime_dependency     'rdf',         '>= 2.2', '< 4.0'
  gem.add_runtime_dependency     'json-ld',     '>= 2.2', '< 4.0'
  gem.add_runtime_dependency     'json-ld-preloaded','>= 2.2', '< 4.0'
  gem.add_runtime_dependency     'ebnf',        '~> 1.1'
  gem.add_runtime_dependency     'sxp',         '~> 1.0'
  #gem.add_runtime_dependency     'rdf-xsd',     '~> 3.0'
  #gem.add_runtime_dependency     'sparql',      '~> 3.0'
  gem.add_runtime_dependency     'rdf-xsd',     '>= 2.2', '< 4.0'
  gem.add_runtime_dependency     'sparql',      '>= 2.2', '< 4.0'

  #gem.add_development_dependency 'rdf-spec',    '~> 3.0'
  #gem.add_development_dependency 'rdf-turtle',  '~> 3.0'
  gem.add_development_dependency 'rdf-spec',    '>= 2.2', '< 4.0'
  gem.add_development_dependency 'rdf-turtle',  '>= 2.2', '< 4.0'
  gem.add_development_dependency 'rspec',       '~> 3.7'
  gem.add_development_dependency 'rspec-its',   '~> 1.2'
  gem.add_development_dependency 'yard',        '~> 0.9.12'

  gem.post_install_message       = nil
end
