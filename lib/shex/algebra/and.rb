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
    # @param [RDF::Resource] n
    # @return [Boolean] `true` if satisfied, `false` if it does not apply
    # @raise [ShEx::NotSatisfied] if not satisfied
    def satisfies?(n)
      status ""
      unless operands.select {|o| o.is_a?(Satisfiable)}.all? {|op| op.satisfies?(n)}
        not_satisfied "Expected all to match"
      end
      status("satisfied")
    end
  end
end
