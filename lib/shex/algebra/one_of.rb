module ShEx::Algebra
  ##
  class OneOf < Operator
    include TripleExpression
    NAME = :oneOf

    ##
    # `expr` is a OneOf and there is some shape expression `se2` in shapeExprs such that a `matches(T, se2, m)`...
    #
    # @param [Array<RDF::Statement>] t
    # @param [RDF::Queryable] g
    # @param [Hash{RDF::Resource => RDF::Resource}] m
    # @return [Array<RDF::Statement]
    def matches(t, g, m)
      result = []
      # FIXME Cardinality?
      matched_something = operands.select {|o| o.is_a?(TripleExpression)}.any? do |op|
        begin
          result += op.matches(t, g, m)
          status "matched #{t.first.to_sxp}"
        rescue NotMatched => e
          log_recover("oneOf: ignore error: #{e.message}", depth: options.fetch(:depth, 0))
          false
        end
      end
      not_matched "Expected some expression to match" unless matched_something

      # Last, evaluate semantic acts
      operands.select {|o| o.is_a?(SemAct)}.all? do |op|
        op.satisfies?(result)
      end unless result.empty?

      status "one of satisfied"
      result
    end
  end
end
