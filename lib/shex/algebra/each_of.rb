module ShEx::Algebra
  ##
  class EachOf < Operator
    include TripleExpression
    NAME = :eachOf

    ##
    # expr is an EachOf and there is some partition of T into T1, T2,… such that for every expression expr1, expr2,… in shapeExprs, matches(Tn, exprn, m)...
    #
    # @param [Array<RDF::Statement>] t
    # @param [RDF::Queryable] g
    # @param [Hash{RDF::Resource => RDF::Resource}] m
    # @return [Array<RDF::Statement>]
    # @raise NotMatched, ShEx::NotSatisfied
    def matches(t, g, m)
      status ""
      results = []
      # FIXME Cardinality?
      operands.select {|o| o.is_a?(TripleExpression)}.all? do |op|
        results += op.matches(t, g, m)
      end

      # Last, evaluate semantic acts
      operands.select {|o| o.is_a?(SemAct)}.all? do |op|
        op.satisfies?(results)
      end unless results.empty?

      results
    rescue NotMatched => e
      not_matched(e.message)
      raise
    end

    ##
    # Predicates associated with this TripleExpression
    # @return [Array<RDF::URI>]
    def predicates
      operands.select {|o| o.is_a?(TripleExpression)}.map(&:predicates).flatten.uniq
    end
  end
end
