module ShEx::Algebra
  ##
  class TripleConstraint < Operator
    include TripleExpression
    NAME = :tripleConstraint

    ##
    # In this case, we accept an array of statements, and match based on cardinality.
    #
    # @param [Array<RDF::Statement>] t
    # @param [RDF::Queryable] g
    # @param [Hash{RDF::Resource => RDF::Resource}] m
    # @return [Array<RDF::Statement>]
    # @raise NotMatched, ShEx::NotSatisfied
    def matches(t, g, m)
      max = maximum
      results = t.select do |statement|
        if max > 0
          value = inverse? ? statement.subject : statement.object

          max -= 1 if statement.predicate == predicate && shape_expr_satisfies?(shape, value, g, m)
        end
      end

      # Max violations handled in Shape
      raise(NotMatched, "Minimum Cardinality Violation: #{results.length} < #{minimum}") if
        results.length < minimum

      # Last, evaluate semantic acts
      operands.select {|o| o.is_a?(SemAct)}.all? do |op|
        op.satisfies?(results)
      end unless results.empty?

      results
    end

    def shape_expr_satisfies?(shape, value, g, m)
      shape.nil? || shape.satisfies?(value, g, m)
    rescue ShEx::NotSatisfied
      false
    end

    def predicate
      operands.detect {|o| o.is_a?(RDF::URI)}
    end

    def predicates
      [predicate]
    end

    def inverse?
      operands.include?(:inverse)
    end

    def shape
      operands.detect {|o| o.is_a?(Satisfiable)}
    end
  end
end
