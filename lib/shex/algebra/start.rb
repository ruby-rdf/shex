module ShEx::Algebra
  ##
  class Start < Operator::Unary
    NAME = :start

    #
    # @param [RDF::Resource] n
    # @param [RDF::Queryable] g
    # @param [Hash{RDF::Resource => RDF::Resource}] m
    # @return [Boolean] `true` if satisfied, `false` if it does not apply
    # @raise [ShEx::NotSatisfied] if not satisfied
    def satisfies?(n, g, m)
      status ""
      operands.first.satisfies?(n, g, m)
      status("satisfied")
    rescue ShEx::NotSatisfied => e
      not_satisfied e.message
      raise
    end
  end
end
