module ShEx::Algebra
  ##
  class Shape < Operator
    include Satisfiable
    NAME = :shape

    #
    # The `satisfies` semantics for a `Shape` depend on a matches function defined below. For a node `n`, shape `S`, graph `G`, and shapeMap `m`, `satisfies(n, S, G, m)`.
    # @param [RDF::Resource] n
    # @return [Boolean] `true` if satisfied
    # @raise [ShEx::NotSatisfied] if not satisfied
    def satisfies?(n)
      expression = operands.detect {|op| op.is_a?(TripleExpression)}

      # neigh(G, n) is the neighbourhood of the node n in the graph G.
      #
      #    neigh(G, n) = arcsOut(G, n) ∪ arcsIn(G, n)
      arcs_in = schema.graph.query(object: n).to_a.sort_by(&:to_sxp)
      arcs_out = schema.graph.query(subject: n).to_a.sort_by(&:to_sxp)
      neigh = (arcs_in + arcs_out).uniq

      # `matched` is the subset of statements which match `expression`.
      status("arcsIn: #{arcs_in.count}, arcsOut: #{arcs_out.count}")
      matched = expression ? expression.matches(neigh) : []

      # `remainder` is the set of unmatched statements
      remainder = neigh - matched

      # Let `outs` be the `arcsOut` in `remainder`: `outs = remainder ∩ arcsOut(G, n)`.
      outs = remainder.select {|s| s.subject == n}

      # Let `matchables` be the triples in `outs` whose predicate appears in a `TripleConstraint` in `expression`. If `expression` is absent, `matchables = Ø` (the empty set).
      predicates = expression ? expression.triple_constraints.map(&:predicate).uniq : []
      matchables = outs.select {|s| predicates.include?(s.predicate)}

      # No matchable can be matched by any TripleConstraint in expression
      matchables.each do |statement|
        expression.triple_constraints.each do |expr|
          begin
            status "check matchable #{statement.to_sxp} against #{expr.to_sxp}"
            if statement.predicate == expr.predicate && expr.matches([statement])
              not_satisfied "Unmatched statement: #{statement.to_sxp} matched #{expr.to_sxp}"
            end
          rescue NotMatched
            logger.recovering = false
            # Expected not to match
          end
        end
      end if expression

      # There is no triple in `matchables` which matches a `TripleConstraint` in `expression`.
      # FIXME: Really run against every TripleConstraint?

      # Let `unmatchables` be the triples in `outs` which are not in `matchables`.
      unmatchables = outs - matchables

      # There is no triple in matchables whose predicate does not appear in extra.
      matchables.each do |statement|
        not_satisfied "Statement remains with predicate #{statement.predicate} not in extra" unless extra.include?(statement.predicate)
      end

      # closed is false or unmatchables is empty.
      not_satisfied "Unmatchables remain on a closed shape" unless !closed? || unmatchables.empty?

      # Presumably, to be satisfied, there must be some triples in matches

      semantic_actions.all? do |op|
        # FIXME: what triples to run against satisfies?
        op.satisfies?(matched)
      end unless matched.empty?

      true
    rescue NotMatched => e
      logger.recovering = false
      not_satisfied e.message
    end

    ##
    # Included TripleExpressions
    # @return [Array<TripleExpressions>]
    def triple_expressions
      operands.select {|op| op.is_a?(TripleExpression)}
    end

    private
    # There may be multiple extra operands
    def extra
      operands.select {|op| op.is_a?(Array) && op.first == :extra}.inject([]) do |memo, ary|
        memo + Array(ary[1..-1])
      end.uniq
    end
  end
end
