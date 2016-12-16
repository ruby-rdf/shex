module ShEx::Algebra
  ##
  class Start < Operator::Unary
    include Satisfiable
    NAME = :start

    #
    # @param  (see Satisfiable#satisfies?)
    # @return (see Satisfiable#satisfies?)
    # @raise  (see Satisfiable#satisfies?)
    def satisfies?(focus)
      status ""
      matched_op = operands.first.satisfies?(focus)
      satisfy satisfied: matched_op
    rescue ShEx::NotSatisfied => e
      not_satisfied e.message, unsatisfied: e.expression
      raise
    end
  end
end
