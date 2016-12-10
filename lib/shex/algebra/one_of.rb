module ShEx::Algebra
  ##
  class OneOf < Operator
    include TripleExpression
    NAME = :oneOf

    ##
    # `expr` is a OneOf and there is some shape expression `se2` in shapeExprs such that a `matches(T, se2, m)`...
    #
    # @param [Array<RDF::Statement>] t
    # @return [Array<RDF::Statement]
    def matches(t)
      results = []
      statements = t.dup
      num_iters = 0
      max = maximum

      # OneOf is greedy, and consumes triples from every sub-expression, although only one is requred it succeed. Cardinality is somewhat complicated, as if two expressions match, this works for either a cardinality of one or two. Or two passes with just one match on each pass.
      status ""
      while num_iters < max
        matched_something = operands.select {|o| o.is_a?(TripleExpression)}.any? do |op|
          begin
            matched = op.matches(statements)
            results += matched
            statements -= matched
            status "matched #{t.first.to_sxp}"
          rescue NotMatched => e
            log_recover("oneOf: ignore error: #{e.message}", depth: options.fetch(:depth, 0))
            false
          end
        end
        break unless matched_something
        num_iters += 1
        status "matched #{results.length} statements after #{num_iters} iterations"
      end

      # Max violations handled in Shape
      not_matched "Minimum Cardinality Violation: #{num_iters} < #{minimum}" if
        num_iters < minimum

      # Last, evaluate semantic acts
      semantic_actions.all? do |op|
        op.satisfies?(results)
      end unless results.empty?

      status "one of satisfied"
      results
    end
  end
end
