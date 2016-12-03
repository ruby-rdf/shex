module ShEx::Algebra
  ##
  class And < Operator
    include Satisfiable
    NAME = :and

    def initialize(*args, **options)
      case
      when args.length <= 1
        raise ShEx::OperandError, "Expected at least one operand, found #{args.length}"
      end
      super
    end

    #
    # S is a ShapeAnd and for every shape expression se2 in shapeExprs, satisfies(n, se2, G, m).
    def satisfies(n, g, m)
      operands.select {|o| o.is_a?(Satisfiable)}.all? {|op| op.satisfies(n, g, m)}
    end
  end
end
