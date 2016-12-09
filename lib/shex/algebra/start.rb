module ShEx::Algebra
  ##
  class Start < Operator::Unary
    NAME = :start

    #
    # @param [RDF::Resource] n
    # @return [Boolean] `true` if satisfied, `false` if it does not apply
    # @raise [ShEx::NotSatisfied] if not satisfied
    def satisfies?(n)
      status ""
      operands.first.satisfies?(n)
      status("satisfied")
    rescue ShEx::NotSatisfied => e
      not_satisfied e.message
      raise
    end
  end
end
