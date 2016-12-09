module ShEx::Algebra
  ##
  class Shape < Operator
    include Satisfiable
    NAME = :shape

    #
    # The `satisfies` semantics for a `Shape` depend on a matches function defined below. For a node `n`, shape `S`, graph `G`, and shapeMap `m`, `satisfies(n, S, G, m)`.
    # @param [RDF::Resource] n
    # @param [RDF::Queryable] g
    # @param [Hash{RDF::Resource => RDF::Resource}] m
    # @return [Boolean] `true` if satisfied, `false` if it does not apply
    # @raise [ShEx::NotSatisfied] if not satisfied
    def satisfies?(n, g, m)
      expression = operands.detect {|op| op.is_a?(TripleExpression)}

      # neigh(G, n) is the neighbourhood of the node n in the graph G.
      #
      #    neigh(G, n) = arcsOut(G, n) ∪ arcsIn(G, n)
      arcs_in = g.query(object: n).to_a.sort_by(&:to_ntriples)
      arcs_out = g.query(subject: n).to_a.sort_by(&:to_ntriples)
      neigh = (arcs_in + arcs_out).uniq

      # `matched` is the subset of statements which match `expression`.
      # FIXME Cardinality?
      status("arcsIn: #{arcs_in.count}, arcsOut: #{arcs_out.count}")
      matched = expression ? expression.matches(neigh, g, m) : []

      # `remainder` is the set of unmatched statements
      remainder = neigh - matched

      # Let `outs` be the `arcsOut` in `remainder`: `outs = remainder ∩ arcsOut(G, n)`.
      outs = remainder.select {|s| s.subject == n}

      # Let `matchables` be the triples in `outs` whose predicate appears in a `TripleConstraint` in `expression`. If `expression` is absent, `matchables = Ø` (the empty set).
      predicates = expression ? expression.predicates : []
      matchables = outs.select {|s| predicates.include?(s.predicate)}
      # Fixme: reduce by filtering against all TripleConstraints, causes not to match

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

      operands.select {|o| o.is_a?(SemAct)}.all? do |op|
        # FIXME: what triples to run against satisfies?
        op.satisfies?(matched)
      end unless matched.empty?

      true
    rescue NotMatched => e
      logger.recovering = false
      not_satisfied e.message
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
