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
      any_not_satisfied = false
      operands.select {|o| o.is_a?(Satisfiable)}.any? do |op|
        begin
          op.satisfies?(focus)
          status "satisfied #{focus}"
          return true
        rescue ShEx::NotSatisfied => e
          log_recover("or: ignore error: #{e.message}", depth: options.fetch(:depth, 0))
          any_not_satisfied = e
          false
        end
      end

      not_satisfied "Expected some expression to be satisfied"
    end
  end
end
