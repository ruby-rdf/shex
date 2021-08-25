#!/usr/bin/env ruby
$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), 'lib')))
require 'rubygems'
require 'yard'
require 'rspec/core/rake_task'

namespace :gem do
  desc "Build the shex-#{File.read('VERSION').chomp}.gem file"
  task :build do
    sh "gem build shex.gemspec && mv shex-#{File.read('VERSION').chomp}.gem pkg/"
  end

  desc "Release the shex-#{File.read('VERSION').chomp}.gem file"
  task :release do
    sh "gem push pkg/shex-#{File.read('VERSION').chomp}.gem"
  end
end

desc 'Default: run specs.'
task default: :spec

RSpec::Core::RakeTask.new(:spec)

desc 'Create versions of ebnf files in etc'
task etc: %w{etc/shex.sxp etc/shex.html etc/shex.peg.sxp}

desc 'Build first, follow and branch tables'
task meta: "lib/shex/meta.rb"

file "lib/shex/meta.rb" => "etc/shex.ebnf" do |t|
  sh %{
    ebnf --peg --format rb \
      --input-format native \
      --mod-name ShEx::Meta \
      --output lib/shex/meta.rb \
      etc/shex.ebnf
  }
end

file "etc/shex.peg.sxp" => "etc/shex.ebnf" do |t|
  sh %{
    ebnf --peg --format sxp \
      --input-format native \
      --output etc/shex.peg.sxp \
      etc/shex.ebnf
  }
end

file "etc/shex.sxp" => "etc/shex.ebnf" do |t|
  sh %{
    ebnf --input-format native --format sxp \
      --output etc/shex.sxp \
      etc/shex.ebnf
  }
end

file "etc/shex.html" => "etc/shex.ebnf" do |t|
  sh %{
    ebnf --input-format native --format html \
      --output etc/shex.html \
      etc/shex.ebnf
  }
end

desc "Build shex JSON-LD context cache"
task context: "lib/shex/shex_context.rb"
file "lib/shex/shex_context.rb" do
  require 'json/ld'
  File.open("lib/shex/shex_context.rb", "w") do |f|
    c = JSON::LD::Context.new().parse("http://www.w3.org/ns/shex.jsonld")
    f.write c.to_rb
  end
end