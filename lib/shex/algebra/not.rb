module ShEx::Algebra
  ##
  class Not < Operator::Unary
    include Satisfiable
    NAME = :not

    #
    # S is a ShapeNot and for the shape expression se2 at shapeExpr, notSatisfies(n, se2, G, m).
    # @param  (see Satisfiable#satisfies?)
    # @return (see Satisfiable#satisfies?)
    # @raise  (see Satisfiable#satisfies?)
    # @see [https://shexspec.github.io/spec/#shape-expression-semantics]
    def satisfies?(focus)
      status ""
      satisfied_op = begin
        operands.first.satisfies?(focus)
      rescue ShEx::NotSatisfied => e
        return satisfy satisfied: e.expression.unsatisfied
      end
      not_satisfied "Expression should not have matched", unsatisfied: satisfied_op
    end
  end
end
