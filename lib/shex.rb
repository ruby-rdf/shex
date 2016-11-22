require 'sparql/extensions'

##
# A ShEx runtime for RDF.rb.
#
# @see https://shexspec.github.io/spec/#shexc
module ShEx
  autoload :Parser, 'shex/parser'

  ##
  # Parse the given ShEx `query` string.
  #
  # @example
  #   query = ShEx.parse("...")
  #
  # @param  [IO, StringIO, String, #to_s]  query
  # @param  [Hash{Symbol => Object}] options
  # @option options [Boolean] :update (false)
  #   Parse starting with UpdateUnit production, QueryUnit otherwise.
  # @return [xxx]
  # @raise  [Parser::Error] on invalid input
  def self.parse(shex, options = {})
    query = Parser.new(query, options).parse(:shexDoc)
  end

  ##
  # Parse and execute the given ShEx `expression` string against `queriable`.
  def self.execute(shex, queryable, options = {}, &block)
    query = self.parse(shex, options)
    queryable = queryable || RDF::Repository.new

  rescue Parser::Error => e
    raise MalformedQuery, e.message
  end
end
