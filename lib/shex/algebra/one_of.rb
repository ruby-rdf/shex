module ShEx::Algebra
  ##
  class OneOf < Operator
    include TripleExpression
    NAME = :oneOf

    ##
    # `expr` is a OneOf and there is some shape expression `se2` in shapeExprs such that a `matches(T, se2, m)`...
    #
    # @param [Array<RDF::Statement>] statements
    # @return [Array<RDF::Statement]
    def matches(statements)
      results, satisfied, unsatisfied = [], [], []
      num_iters, max = 0, maximum

      # OneOf is greedy, and consumes triples from every sub-expression, although only one is requred it succeed. Cardinality is somewhat complicated, as if two expressions match, this works for either a cardinality of one or two. Or two passes with just one match on each pass.
      status ""
      while num_iters < max
        matched_something = operands.select {|o| o.is_a?(TripleExpression)}.any? do |op|
          begin
            matched_op = op.matches(statements)
            satisfied << matched_op
            results += matched_op.matched
            statements -= matched_op.matched
            status "matched #{matched_op.matched.to_sxp}"
          rescue ShEx::NotMatched => e
            status "not matched: #{e.message}"
            op = op.dup
            op.unmatched = statements - results
            unsatisfied << op
            false
          end
        end
        break unless matched_something
        num_iters += 1
        status "matched #{results.length} statements after #{num_iters} iterations"
      end

      # Max violations handled in Shape
      if num_iters < minimum
        raise ShEx::NotMatched, "Minimum Cardinality Violation: #{results.length} < #{minimum}"
      end

      # Last, evaluate semantic acts
      semantic_actions.all? do |op|
        op.satisfies?(results)
      end unless results.empty?

      satisfy matched: results, satisfied: satisfied, unsatisfied: unsatisfied
    rescue ShEx::NotMatched, ShEx::NotSatisfied => e
      not_matched e.message,
                  matched:   results,   unmatched:   (statements - results),
                  satisfied: satisfied, unsatisfied: unsatisfied
    end
  end
end
