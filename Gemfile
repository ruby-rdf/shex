source "https://rubygems.org"

gemspec

gem 'rdf',              git: "https://github.com/ruby-rdf/rdf",               branch: "develop"
gem 'json-ld',          git: "https://github.com/ruby-rdf/json-ld",           branch: "develop"
gem 'json-ld-preloaded',git: "https://github.com/ruby-rdf/json-ld-preloaded", branch: "develop"

group :development, :test do
  gem 'ebnf',       git: "https://github.com/gkellogg/ebnf",        branch: "develop"
  gem 'linkeddata', git: "https://github.com/ruby-rdf/linkeddata",  branch: "develop"
  gem 'sxp',        git: "https://github.com/dryruby/sxp.rb",       branch: "develop"
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
