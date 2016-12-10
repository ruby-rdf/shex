module ShEx::Algebra
  ##
  class Start < Operator::Unary
    NAME = :start

    #
    # @param [RDF::Resource] n
    # @return [Boolean] `true` if satisfied
    # @raise [ShEx::NotSatisfied] if not satisfied
    def satisfies?(n)
      status ""
      operands.first.satisfies?(n)
      status("satisfied")
      true
    rescue ShEx::NotSatisfied => e
      not_satisfied e.message
      raise
    end
  end
end
