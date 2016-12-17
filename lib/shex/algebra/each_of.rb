module ShEx::Algebra
  ##
  class EachOf < Operator
    include TripleExpression
    NAME = :eachOf

    ##
    # Creates an operator instance from a parsed ShExJ representation
    # @param (see Operator#from_shexj)
    # @return [Operator]
    def self.from_shexj(operator, options = {})
      raise ArgumentError unless operator.is_a?(Hash) && operator['type'] == 'EachOf'
      raise ArgumentError, "missing expressions in #{operator.inspect}" unless operator.has_key?('expressions')
      super
    end

    ##
    # expr is an EachOf and there is some partition of T into T1, T2,… such that for every expression expr1, expr2,… in shapeExprs, matches(Tn, exprn, m)...
    #
    # @param [Array<RDF::Statement>] statements
    # @return [Array<RDF::Statement>]
    # @raise [ShEx::NotMatched]
    def matches(statements)
      status ""
      results, satisfied, unsatisfied = [], [], []
      num_iters, max = 0, maximum

      while num_iters < max
        begin
          matched_this_iter = []
          operands.select {|o| o.is_a?(TripleExpression)}.all? do |op|
            begin
              matched_op = op.matches(statements - matched_this_iter)
              satisfied << matched_op
              matched_this_iter += matched_op.matched
            rescue ShEx::NotMatched => e
              status "not matched: #{e.message}"
              op = op.dup
              op.unmatched = statements - matched_this_iter
              unsatisfied << op
              raise
            end
          end
          results += matched_this_iter
          statements -= matched_this_iter
          num_iters += 1
          status "matched #{results.length} statements after #{num_iters} iterations"
        rescue ShEx::NotMatched => e
          status "no match after #{num_iters} iterations (ignored)"
          break
        end
      end

      # Max violations handled in Shape
      if num_iters < minimum
        raise ShEx::NotMatched, "Minimum Cardinality Violation: #{results.length} < #{minimum}"
      end

      # Last, evaluate semantic acts
      semantic_actions.all? do |op|
        op.satisfies?(results)
      end unless results.empty?

      satisfy matched: results, satisfied: satisfied
    rescue ShEx::NotMatched, ShEx::NotSatisfied => e
      not_matched e.message,
                  matched:   results,   unmatched:   (statements - results),
                  satisfied: satisfied, unsatisfied: unsatisfied
    end
  end
end
