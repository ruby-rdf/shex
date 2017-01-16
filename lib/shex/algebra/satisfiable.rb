require 'sparql/algebra'

module ShEx::Algebra
  # Implements `satisfies?` and `not_satisfies?`
  module Satisfiable
    ##
    # Satisfies method
    # @param [RDF::Resource] focus
    # @return [Operator] with `matched` and `satisfied` accessors for matched triples and sub-expressions
    # @raise [ShEx::NotMatched] with `expression` accessor to access `matched` and `unmatched` statements along with `satisfied` and `unsatisfied` operations.
    # @see [https://shexspec.github.io/spec/#shape-expression-semantics]
    def satisfies?(focus, depth: 0)
      raise NotImplementedError, "#satisfies? Not implemented in #{self.class}"
    end

    # This operator includes Satisfiable
    def satisfiable?; true; end
  end
end
