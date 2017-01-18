module ShEx::Algebra
  ##
  class TripleConstraint < Operator
    include TripleExpression
    NAME = :tripleConstraint

    ##
    # Creates an operator instance from a parsed ShExJ representation
    # @param (see Operator#from_shexj)
    # @return [Operator]
    def self.from_shexj(operator, options = {})
      raise ArgumentError unless operator.is_a?(Hash) && operator['type'] == 'TripleConstraint'
      raise ArgumentError unless operator.has_key?('predicate')
      super
    end

    ##
    # In this case, we accept an array of statements, and match based on cardinality.
    #
    # @param  (see TripleExpression#matches)
    # @return (see TripleExpression#matches)
    # @raise  (see TripleExpression#matches)
    def matches(arcs_in, arcs_out, depth: 0)
      status "predicate #{predicate}", depth: depth
      results, satisfied, unsatisfied = [], [], []
      num_iters, max = 0, maximum

      statements = inverse? ? arcs_in : arcs_out
      statements.select {|st| st.predicate == predicate}.each do |statement|
        break if num_iters == max # matched enough

        value = inverse? ? statement.subject : statement.object

        begin
          shape && (matched_shape = shape.satisfies?(value, depth: depth + 1))
          status "matched #{statement.to_sxp}", depth: depth
          if matched_shape
            matched_shape.matched = [statement]
            statement = statement.dup.extend(ReferencedStatement)
            statement.referenced = matched_shape
            satisfied << matched_shape
          end
          results << statement
          num_iters += 1
        rescue ShEx::NotSatisfied => e
          status "not satisfied: #{e.message}", depth: depth
          unsatisfied << e.expression
          statement = statement.dup.extend(ReferencedStatement)
          unmatched << statement.referenced = shape
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

      satisfy matched: results, satisfied: satisfied, unsatisfied: unsatisfied, depth: depth
    rescue ShEx::NotMatched, ShEx::NotSatisfied => e
      not_matched e.message,
                  matched:   results,   unmatched:   (statements - results),
                  satisfied: satisfied, unsatisfied: unsatisfied, depth: depth
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
