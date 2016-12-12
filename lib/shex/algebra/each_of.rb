module ShEx::Algebra
  ##
  class EachOf < Operator
    include TripleExpression
    NAME = :eachOf

    ##
    # expr is an EachOf and there is some partition of T into T1, T2,… such that for every expression expr1, expr2,… in shapeExprs, matches(Tn, exprn, m)...
    #
    # @param [Array<RDF::Statement>] statements
    # @return [Array<RDF::Statement>]
    # @raise NotMatched, ShEx::NotSatisfied
    def matches(statements)
      status ""
      results = []
      num_iters = 0
      max = maximum

      while num_iters < max
        begin
          matched_this_iter = []
          operands.select {|o| o.is_a?(TripleExpression)}.all? do |op|
            matched = op.matches(statements - matched_this_iter)
            matched_this_iter += matched
          end
          results += matched_this_iter
          statements -= matched_this_iter
          num_iters += 1
          status "matched #{results.length} statements after #{num_iters} iterations"
        rescue NotMatched => e
          log_recover("eachOf: ignore error: #{e.message}", depth: options.fetch(:depth, 0))
          break
        end
      end

      # Max violations handled in Shape
      not_matched "Minimum Cardinality Violation: #{num_iters} < #{minimum}" if
        num_iters < minimum

      # Last, evaluate semantic acts
      semantic_actions.all? do |op|
        op.satisfies?(results)
      end unless results.empty?

      status "each of satisfied"
      results
    rescue NotMatched => e
      not_matched(e.message)
      raise
    end
  end
end
