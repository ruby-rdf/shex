source "https://rubygems.org"

gemspec

gem 'rdf',      github: "ruby-rdf/rdf",       branch: "develop"

group :development, :test do
  gem 'ebnf',               github: "gkellogg/ebnf",                branch: "develop"
  gem 'linkeddata',         github: "ruby-rdf/linkeddata",          branch: "develop"
  gem 'rdf-isomorphic',     github: "ruby-rdf/rdf-isomorphic",      branch: "develop"
  gem 'rdf-turtle',         github: "ruby-rdf/rdf-turtle",          branch: "develop"
  gem 'rdf-xsd',            github: "ruby-rdf/rdf-xsd",             branch: "develop"
  gem 'sxp',                github: "dryruby/sxp.rb",               branch: "develop"
end

group :debug do
  gem "byebug", platform: :mri
end

platforms :rbx do
  gem 'rubysl', '~> 2.0'
  gem 'rubinius', '~> 2.0'
end
