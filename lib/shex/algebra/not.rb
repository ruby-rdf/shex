module ShEx::Algebra
  ##
  class Not < Operator::Unary
    include Satisfiable
    NAME = :not

    #
    # S is a ShapeNot and for the shape expression se2 at shapeExpr, notSatisfies(n, se2, G, m).
    # @param [RDF::Resource] focus
    # @return [Boolean] `true` when satisfied, meaning that the operand was not satisfied
    # @raise [ShEx::NotSatisfied] if not satisfied, meaning that the operand was satisfied
    def satisfies?(focus)
      status ""
      operands.last.not_satisfies?(focus)
      status "not satisfied"
      true
    end
  end
end
