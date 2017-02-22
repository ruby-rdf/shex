source "https://rubygems.org"

gemspec

gem 'rdf',              github: "ruby-rdf/rdf",               branch: "develop"
gem 'json-ld',          github: "ruby-rdf/json-ld",           branch: "develop"
gem 'json-ld-preloaded',github: "ruby-rdf/json-ld-preloaded", branch: "develop"

group :development, :test do
  gem 'ebnf',       github: "gkellogg/ebnf",        branch: "develop"
  gem 'linkeddata', github: "ruby-rdf/linkeddata",  branch: "develop"
  gem 'sxp',        github: "dryruby/sxp.rb",       branch: "develop"
  gem 'simplecov',  require: false
  gem 'coveralls',  require: false
  gem 'earl-report'
end

group :debug do
  gem "byebug", platform: :mri
end

platforms :rbx do
  gem 'rubysl', '~> 2.0'
  gem 'rubinius', '~> 2.0'
end
