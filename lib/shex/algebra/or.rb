module ShEx::Algebra
  ##
  class Or < Operator
    include Satisfiable
    NAME = :or

    def initialize(*args, **options)
      case
      when args.length <= 1
        raise ShEx::OperandError, "Expected at least one operand, found #{args.length}"
      end
      super
    end

    #
    # S is a ShapeOr and there is some shape expression se2 in shapeExprs such that satisfies(n, se2, G, m).
    def satisfies(n, g, m)
      operands.select {|o| o.is_a?(Satisfiable)}.any? {|op| op.satisfies(n, g, m)}
    end
  end
end
