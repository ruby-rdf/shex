module ShEx::Algebra
  ##
  class And < Operator
    include Satisfiable
    NAME = :and

    def initialize(*args, **options)
      case
      when args.length <= 1
        raise ArgumentError, "wrong number of arguments (given #{args.length}, expected 1..)"
      end
      super
    end

    #
    # S is a ShapeAnd and for every shape expression se2 in shapeExprs, satisfies(n, se2, G, m).
    # @param [RDF::Resource] n
    # @return [Boolean] `true` when satisfied
    # @raise [ShEx::NotSatisfied] if not satisfied
    def satisfies?(focus)
      status ""
      expressions = operands.select {|o| o.is_a?(Satisfiable)}
      satisfied = []

      # Operand raises NotSatisfied, so no need to check here.
      operands.select {|o| o.is_a?(Satisfiable)}.each do |op|
        op.satisfies?(focus)
        satisfied << op
      end
      status("satisfied")
      true
    rescue ShEx::NotSatisfied => e
      unsatisfied = (expressions - satisfied)
      not_satisfied e.message,
                    satisfied:   satisfied,
                    unsatisfied: (expressions - satisfied)
    end
  end
end
