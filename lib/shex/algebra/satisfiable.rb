require 'sparql/algebra'
require 'sparql/extensions'

module ShEx::Algebra
  # Implements `satisfies?` and `not_satisfies?`
  module Satisfiable
    ##
    # Satisfies method
    # @param [RDF::Resource] n
    # @param [RDF::Queryable] g
    # @param [Hash{RDF::Resource => RDF::Resource}] m
    # @return [Boolean] `true` if satisfied, `false` if it does not apply
    # @raise [NotSatisfied] if not satisfied
    # @see [https://shexspec.github.io/spec/#shape-expression-semantics]
    def satisfies?(n, g, m)
      raise NotImplementedError, "#satisfies? Not implemented in #{self.class}"
    end

    ##
    # Satisfies method
    # @param [RDF::Resource] n
    # @param [ShEx::Operator] se
    # @param [RDF::Queryable] g
    # @param [Hash{RDF::Resource => RDF::Resource}] m
    # @return [Boolean] `true` if not satisfied, `false` if it does not apply
    # @raise [NotSatisfied] if satisfied
    # @see [https://shexspec.github.io/spec/#shape-expression-semantics]
    def not_satisfies?(n, se, g, m)
      raise NotSatisfied if satisfies(n, se, g, m)
      false   # doesn't apply
    rescue NotSatisfied
      true
    end
    alias_method :notSatisfies?, :not_satisfies?

    # This operator includes Satisfiable
    def satisfiable?; true; end
  end
end
