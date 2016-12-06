module ShEx::Algebra
  ##
  class SomeOf < Operator
    include TripleExpression
    NAME = :someOf

    ##
    # `expr` is a SomeOf and there is some shape expression `se2` in shapeExprs such that a `matches(T, se2, m)`...
    #
    # @param [Array<RDF::Statement>] t
    # @param [RDF::Queryable] g
    # @param [Hash{RDF::Resource => RDF::Resource}] m
    # @return [Array<RDF::Statement]
    def matches(t, g, m)
      result = []
      operands.select {|o| o.is_a?(TripleExpression)}.any? do |op|
        this_result = op.matches(t, g, m)
        if this_result.empty?
          false
        else
          result += this_result
        end
      end

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
