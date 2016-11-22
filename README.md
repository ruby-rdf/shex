# ShEx: Shape Expression language for Ruby

This is a pure-Ruby library for working with the [Shape Expressions Language][ShEx] to validate the shape of [RDF][] graphs.

* <http://ruby-rdf.github.com/shex>

[![Gem Version](https://badge.fury.io/rb/shex.png)](http://badge.fury.io/rb/shex)
[![Build Status](https://travis-ci.org/ruby-rdf/shex.png?branch=master)](http://travis-ci.org/ruby-rdf/shex)
[![Coverage Status](https://coveralls.io/repos/ruby-rdf/shex/badge.svg)](https://coveralls.io/r/ruby-rdf/shex)
[![Join the chat at https://gitter.im/ruby-rdf/rdf](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/ruby-rdf/rdf?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

## Features

* 100% pure Ruby with minimal dependencies and no bloat.
* Fully compatible with [RDF 1.1][] specifications.
* 100% free and unencumbered [public domain](http://unlicense.org/) software.

## Documentation

<http://rubydoc.info/github/ruby-rdf/shex>


## Dependencies

* [Ruby](http://ruby-lang.org/) (>= 2.0)
* [RDF.rb](http://rubygems.org/gems/rdf) (>= 2.1)

## Installation

The recommended installation method is via [RubyGems](http://rubygems.org/).
To install the latest official release of RDF.rb, do:

    % [sudo] gem install shex             # Ruby 2+

## Download

To get a local working copy of the development repository, do:

    % git clone git://github.com/ruby-rdf/shex.git

Alternatively, download the latest development version as a tarball as
follows:

    % wget http://github.com/ruby-rdf/shex/tarball/master

## Resources

* <http://rubydoc.info/github/ruby-rdf/shex>
* <http://github.com/ruby-rdf/shex>
* <http://rubygems.org/gems/shex>

## Mailing List

* <http://lists.w3.org/Archives/Public/public-rdf-ruby/>

## Author

* [Gregg Kellogg](http://github.com/gkellogg) - <http://greggkellogg.net/>

## Contributing

This repository uses [Git Flow](https://github.com/nvie/gitflow) to mange development and release activity. All submissions _must_ be on a feature branch based on the _develop_ branch to ease staging and integration.

* Do your best to adhere to the existing coding conventions and idioms.
* Don't use hard tabs, and don't leave trailing whitespace on any line.
  Before committing, run `git diff --check` to make sure of this.
* Do document every method you add using [YARD][] annotations. Read the
  [tutorial][YARD-GS] or just look at the existing code for examples.
* Don't touch the `.gemspec` or `VERSION` files. If you need to change them,
  do so on your private branch only.
* Do feel free to add yourself to the `CREDITS` file and the
  corresponding list in the the `README`. Alphabetical order applies.
* Don't touch the `AUTHORS` file. If your contributions are significant
  enough, be assured we will eventually add you in there.
* Do note that in order for us to merge any non-trivial changes (as a rule
  of thumb, additions larger than about 15 lines of code), we need an
  explicit [public domain dedication][PDD] on record from you.

## License

This is free and unencumbered public domain software. For more information,
see <http://unlicense.org/> or the accompanying {file:LICENSE} file.

[ShEx]:             https://shexspec.github.io/spec/
[RDF]:              http://www.w3.org/RDF/
