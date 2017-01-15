source "https://rubygems.org"

gemspec

gem 'rdf',          github: "ruby-rdf/rdf",         branch: "develop"

group :development, :test do
  gem 'ebnf',       github: "gkellogg/ebnf",        branch: "develop"
  gem 'linkeddata', github: "ruby-rdf/linkeddata",  branch: "develop"
  gem 'sxp',        github: "dryruby/sxp.rb",       branch: "develop"
  #gem 'simplecov',  require: false
  gem 'simplecov',  github: 'colszowka/simplecov'
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
