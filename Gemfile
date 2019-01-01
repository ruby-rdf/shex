source "https://rubygems.org"

gemspec

gem 'rdf',              git: "https://github.com/ruby-rdf/rdf",               branch: "develop"
gem 'json-ld',          git: "https://github.com/ruby-rdf/json-ld",           branch: "develop"
gem 'json-ld-preloaded',git: "https://github.com/ruby-rdf/json-ld-preloaded", branch: "develop"

group :development, :test do
  gem 'ebnf',       git: "https://github.com/dryruby/ebnf",         branch: "develop"
  gem 'linkeddata', git: "https://github.com/ruby-rdf/linkeddata",  branch: "develop"
  gem 'rdf-isomorphic', git: "https://github.com/ruby-rdf/rdf-isomorphic",  branch: "develop"
  gem 'rdf-turtle', git: "https://github.com/ruby-rdf/rdf-turtle",  branch: "develop"
  gem 'rdf-xsd',    git: "https://github.com/ruby-rdf/rdf-xsd",     branch: "develop"
  gem 'rdf-spec',   git: "https://github.com/ruby-rdf/rdf-spec",    branch: "develop"
  gem 'sparql',     git: "https://github.com/ruby-rdf/sparql",      branch: "develop"
  gem 'sxp',        git: "https://github.com/dryruby/sxp.rb",       branch: "develop"
  gem 'simplecov',  require: false
  gem 'coveralls',  require: false
  gem 'earl-report'
end

group :debug do
  gem "byebug", platform: :mri
end
