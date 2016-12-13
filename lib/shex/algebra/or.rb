module ShEx::Algebra
  ##
  class Or < Operator
    include Satisfiable
    NAME = :or

    def initialize(*args, **options)
      case
      when args.length <= 1
        raise ArgumentError, "wrong number of arguments (given #{args.length}, expected 1..)"
      end
      super
    end

    #
    # S is a ShapeOr and there is some shape expression se2 in shapeExprs such that satisfies(n, se2, G, m).
    # @param [RDF::Resource] focus
    # @return [Boolean] `true` if satisfied, `false` if it does not apply
    # @raise [ShEx::NotSatisfied] if not satisfied
    def satisfies?(focus)
      status ""
      expressions = operands.select {|o| o.is_a?(Satisfiable)}
      unsatisfied = []
      expressions.any? do |op|
        begin
          op.satisfies?(focus)
          status "satisfied #{focus}"
          return true
        rescue ShEx::NotSatisfied => e
          status "unsatisfied #{focus}"
          op = op.dup
          op.matched = e.expression.matched
          op.unmatched = e.expression.unmatched
          op.satisfied = e.expression.satisfied
          op.unsatisfied = e.expression.unsatisfied
          unsatisfied << op
          status("unsatisfied: #{e.message}")
          false
        end
      end

      not_satisfied "Expected some expression to be satisfied",
                    matched:     unsatisfied.map(&:matched).flatten,
                    unmatched:   unsatisfied.map(&:unmatched).flatten,
                    unsatisfied: unsatisfied
    end
  end
end
