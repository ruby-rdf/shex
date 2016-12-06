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
    # @param [RDF::Resource] n
    # @param [RDF::Queryable] g
    # @param [Hash{RDF::Resource => RDF::Resource}] m
    # @return [Boolean] `true` if satisfied, `false` if it does not apply
    # @raise [NotSatisfied] if not satisfied
    def satisfies?(n, g, m)
      any_not_satisfied = false
      operands.select {|o| o.is_a?(Satisfiable)}.any? do |op|
        begin
          op.satisfies?(n, g, m)
        rescue NotSatisfied => e
          any_not_satisfied = e
          false
        end
      end

      raise any_not_satisfied if any_not_satisfied
      false
    end
  end
end
