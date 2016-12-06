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
    # @raise [NotSatisfied] if not satisfied
    def satisfies?(n, g, m)
      expression = operands.detect {|op| op.is_a?(TripleExpression)}

      # neigh(G, n) is the neighbourhood of the node n in the graph G.
      #
      #    neigh(G, n) = arcsOut(G, n) ∪ arcsIn(G, n)
      arcs_in = g.query(object: n).to_a
      arcs_out = g.query(subject: n).to_a
      neigh = (arcs_in + arcs_out).uniq

      # `matched` is the subset of statements which match `expression`.
      matched = expression ? expression.matches(neigh, g, m) : []
      raise NotSatisfied if expression && matched.empty?

      # `remainder` is the set of unmatched statements
      remainder = neigh - matched

      # Let `outs` be the `arcsOut` in `remainder`: `outs = remainder ∩ arcsOut(G, n)`.
      outs = remainder.select {|s| s.subject == n}

      # Let `matchables` be the triples in `outs` whose predicate appears in a `TripleConstraint` in `expression`. If `expression` is absent, `matchables = Ø` (the empty set).
      predicates = expression ? expression.predicates : []
      matchables = outs.select {|s| predicates.include?(s.predicate)}

      # There is no triple in `matchables` which matches a `TripleConstraint` in `expression`.
      # FIXME: Really run against every TripleConstraint?

      # Let `unmatchables` be the triples in `outs` which are not in `matchables`.
      unmatchables = outs - matchables

      # There is no triple in matchables whose predicate does not appear in extra.
      matchables.each do |statement|
        raise NotSatisfied unless extra.include?(statement.predicate)
      end

      # closed is false or unmatchables is empty.
      raise NotSatisfied unless !closed? || unmatchables.empty?

      # Presumably, to be satisfied, there must be some triples in matches

      operands.select {|o| o.is_a?(SemAct)}.all? do |op|
        # FIXME: what triples to run against satisfies?
        op.satisfies?(matched)
      end unless matched.empty?

      true
    end

    private
    def extra
      Array(Array(operands.detect {|op| op.is_a?(Array) && op.first == :extra})[1..-1])
    end
  end
end
