module ShEx::Algebra
  ##
  class Not < Operator::Unary
    include Satisfiable
    NAME = :not

    #
    # S is a ShapeNot and for the shape expression se2 at shapeExpr, notSatisfies(n, se2, G, m).
    # @param [RDF::Resource] n
    # @return [Boolean] `true` when satisfied, meaning that the operand was not satisfied
    # @raise [ShEx::NotSatisfied] if not satisfied, meaning that the operand was satisfied
    def satisfies?(n)
      status ""
      operands.last.not_satisfies?(n)
      status "not satisfied"
      true
    end
  end
end
