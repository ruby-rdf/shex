module ShEx::Algebra
  ##
  class Shape < Operator
    include Satisfiable
    NAME = :shape

    #
    # The `satisfies` semantics for a `Shape` depend on a matches function defined below. For a node `n`, shape `S`, graph `G`, and shapeMap `m`, `satisfies(n, S, G, m)`.
    def satisfies(n, g, m)
      operands.select {|o| o.is_a?(Satisfiable)}.all? {|op| op.satisfies(n, g, m)}
    end
  end
end
