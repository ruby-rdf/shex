module ShEx::Algebra
  ##
  class TripleConstraint < Operator
    include TripleExpression
    NAME = :tripleConstraint

    ##
    # `expr` is a SomeOf and there is some shape expression `se2` in shapeExprs such that a `matches(T, se2, m)`...
    #
    # In this case, we accept an array of statements, and match based on cardinality.
    #
    # @param [Array<RDF::Statement>] t
    # @param [RDF::Queryable] g
    # @param [Hash{RDF::Resource => RDF::Resource}] m
    # @return [Array<RDF::Statement>]
    def matches(t, g, m)
      results = t.select do |statement|
        value = inverse? ? statement.subject : statement.object

        statement.predicate == predicate &&
        (shape.nil? || begin
          shape.satisfies?(value, g, m)
        rescue NotSatisfied
          false
        end)
      end

      # Last, evaluate semantic acts
      operands.select {|o| o.is_a?(SemAct)}.all? do |op|
        op.satisfies?(results)
      end unless results.empty?

      results
    end

    def predicate
      operands.first
    end

    def predicates
      [operands.first]
    end

    def inverse?
      operands.include?(:inverse)
    end

    def shape
      operands.detect {|o| o.is_a?(Satisfiable)}
    end
  end
end
