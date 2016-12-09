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
      status ""
      max = maximum
      results = t.select do |statement|
        if max > 0
          value = inverse? ? statement.subject : statement.object

          if statement.predicate == predicate && shape_expr_satisfies?(shape, value, g, m)
            status "matched #{statement.to_ntriples}"
            max -= 1
          else
            status "no match #{statement.to_ntriples}"
            false
          end
        else
          false # matched enough
        end
      end

      # Max violations handled in Shape
      not_matched "Minimum Cardinality Violation: #{results.length} < #{minimum}" if
        results.length < minimum

      # Last, evaluate semantic acts
      operands.select {|o| o.is_a?(SemAct)}.all? do |op|
        op.satisfies?(results)
      end unless results.empty?

      results
    end

    def shape_expr_satisfies?(shape, value, g, m)
      shape.nil? || shape.satisfies?(value, g, m)
    rescue ShEx::NotSatisfied => e
      status "ignore error: #{e.message}"
      logger.recovering = false
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
