require 'sparql/algebra'
require 'sparql/extensions'

module ShEx::Algebra
  # Implements `satisfies?` and `not_satisfies?`
  module Satisfiable
    ##
    # Satisfies method
    # @param [RDF::Resource] focus
    # @return [TripleExpression] with `matched` and `satisfied` accessors for matched triples and sub-expressions
    # @raise [ShEx::NotMatched] with `expression` accessor to access `matched` and `unmatched` statements along with `satisfied` and `unsatisfied` operations.
    # @see [https://shexspec.github.io/spec/#shape-expression-semantics]
    def satisfies?(focus)
      raise NotImplementedError, "#satisfies? Not implemented in #{self.class}"
    end

    ##
    # Included TripleExpressions
    # @return [Array<TripleExpressions>]
    def triple_expressions
      operands.select {|o| o.is_a?(Satisfiable)}.map(&:triple_expressions).flatten.uniq
    end

    # This operator includes Satisfiable
    def satisfiable?; true; end
  end
end
