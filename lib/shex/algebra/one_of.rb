module ShEx::Algebra
  ##
  class OneOf < Operator
    include TripleExpression
    NAME = :oneOf

    ##
    # `expr` is a OneOf and there is some shape expression `se2` in shapeExprs such that a `matches(T, se2, m)`...
    #
    # @param [Array<RDF::Statement>] t
    # @param [RDF::Queryable] g
    # @param [Hash{RDF::Resource => RDF::Resource}] m
    # @return [Array<RDF::Statement]
    def matches(t, g, m)
      result = []
      # FIXME Cardinality?
      matched_something = operands.select {|o| o.is_a?(TripleExpression)}.any? do |op|
        begin
          result += op.matches(t, g, m)
        rescue NotMatched
          false
        end
      end
      raise NotMatched, "Expected some expression to match" unless matched_something

      # Last, evaluate semantic acts
      operands.select {|o| o.is_a?(SemAct)}.all? do |op|
        op.satisfies?(result)
      end unless result.empty?

      result
    end

    ##
    # Predicates associated with this TripleExpression
    # @return [Array<RDF::URI>]
    def predicates
      operands.select {|o| o.is_a?(TripleExpression)}.map(&:predicates).flatten.uniq
    end
  end
end
