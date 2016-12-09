module ShEx::Algebra
  ##
  class ShapeExternal < Operator
    include Satisfiable
    NAME = :shapeExternal

    #
    # S is a ShapeRef and the Schema's shapes maps reference to a shape expression se2 and satisfies(n, se2, G, m).
    def satisfies?(n)
      raise NotImplementedError, "#satisfies? ShapeExternal not configured"
    end
  end
end
