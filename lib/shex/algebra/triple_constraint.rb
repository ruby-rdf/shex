module ShEx::Algebra
  ##
  class TripleConstraint < Operator
    include TripleExpression
    NAME = :tripleConstraint

    ##
    # In this case, we accept an array of statements, and match based on cardinality.
    #
    # @param [Array<RDF::Statement>] statements
    # @return [Array<RDF::Statement>]
    # @raise [ShEx::NotMatched]
    def matches(statements)
      status "predicate #{predicate}"
      results, satisfied, unsatisfied = [], [], []
      num_iters, max = 0, maximum

      statements.select {|st| st.predicate == predicate}.each do |statement|
        break if num_iters == max # matched enough

        value = inverse? ? statement.subject : statement.object

        begin
          shape && shape.satisfies?(value)
          status "matched #{statement.to_sxp}"
          if shape
            sh, statement = shape.dup, statement.dup
            statement.referenced = sh
            sh.matched = [statement]
            satisfied << sh
          end
          results << statement
          num_iters += 1
        rescue ShEx::NotSatisfied => e
          status "not satisfied: #{e.message}"
          sh, statement = shape.dup, statement.dup
          statement.referenced = sh
          sh.unmatched = [statement]
        end
      end

      # Max violations handled in Shape
      if results.length < minimum
        raise ShEx::NotMatched, "Minimum Cardinality Violation: #{results.length} < #{minimum}"
      end

      # Last, evaluate semantic acts
      semantic_actions.all? do |op|
        op.satisfies?(results)
      end unless results.empty?

      results
    rescue ShEx::NotMatched, ShEx::NotSatisfied => e
      not_matched e.message,
                  matched:   results,   unmatched:   (statements - results),
                  satisfied: satisfied, unsatisfied: unsatisfied
    end

    def predicate
      operands.detect {|o| o.is_a?(RDF::URI)}
    end


    ##
    # Included TripleConstraints
    # @return [Array<TripleConstraints>]
    def triple_constraints
      [self]
    end

    def inverse?
      operands.include?(:inverse)
    end

    def shape
      operands.detect {|o| o.is_a?(Satisfiable)}
    end
  end
end
