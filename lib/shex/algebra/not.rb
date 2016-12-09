module ShEx::Algebra
  ##
  class Not < Operator::Unary
    include Satisfiable
    NAME = :not

    #
    # S is a ShapeNot and for the shape expression se2 at shapeExpr, notSatisfies(n, se2, G, m).
    # @param [RDF::Resource] n
    # @param [RDF::Queryable] g
    # @param [Hash{RDF::Resource => RDF::Resource}] m
    # @return [Boolean]
    def satisfies?(n, g, m)
      status ""
      operands.last.not_satisfies?(n, g, m)
      status "not satisfied"
    end
  end
end
