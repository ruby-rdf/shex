module ShEx::Algebra
  ##
  class Not < Operator::Unary
    include Satisfiable
    NAME = :not

    #
    # S is a ShapeNot and for the shape expression se2 at shapeExpr, notSatisfies(n, se2, G, m).
    def satisfies(n, g, m)
      !operands.last.satisfies(n, g, m)
    end
  end
end
