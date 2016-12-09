module ShEx::Algebra
  ##
  class Or < Operator
    include Satisfiable
    NAME = :or

    def initialize(*args, **options)
      case
      when args.length <= 1
        log_error("Expected at least one operand, found #{args.length}", depth: options.fetch(:depth, 0), exception: ShEx::OperandError) {"expression: #{self.to_sxp}"}
      end
      super
    end

    #
    # S is a ShapeOr and there is some shape expression se2 in shapeExprs such that satisfies(n, se2, G, m).
    # @param [RDF::Resource] n
    # @param [RDF::Queryable] g
    # @param [Hash{RDF::Resource => RDF::Resource}] m
    # @return [Boolean] `true` if satisfied, `false` if it does not apply
    # @raise [ShEx::NotSatisfied] if not satisfied
    def satisfies?(n, g, m)
      any_not_satisfied = false
      operands.select {|o| o.is_a?(Satisfiable)}.any? do |op|
        begin
          op.satisfies?(n, g, m)
          status "satisfied #{n}"
          return true
        rescue ShEx::NotSatisfied => e
          log_recover("or: ignore error: #{e.message}", depth: options.fetch(:depth, 0))
          any_not_satisfied = e
          false
        end
      end

      not_satisfied "Expected some expression to be satisfied"
      true
    end
  end
end
