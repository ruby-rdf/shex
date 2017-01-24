module ShEx::Algebra
  ##
  class Not < Operator::Unary
    include ShapeExpression
    NAME = :not

    ##
    # Creates an operator instance from a parsed ShExJ representation
    # @param (see Operator#from_shexj)
    # @return [Operator]
    def self.from_shexj(operator, options = {})
      raise ArgumentError unless operator.is_a?(Hash) && operator['type'] == 'ShapeNot'
      raise ArgumentError, "missing shapeExpr in #{operator.inspect}" unless operator.has_key?('shapeExpr')
      super
    end

    #
    # S is a ShapeNot and for the shape expression se2 at shapeExpr, notSatisfies(n, se2, G, m).
    # @param  (see ShapeExpression#satisfies?)
    # @return (see ShapeExpression#satisfies?)
    # @raise  (see ShapeExpression#satisfies?)
    # @see [https://shexspec.github.io/spec/#shape-expression-semantics]
    def satisfies?(focus, depth: 0)
      status ""
      satisfied_op = begin
        operands.last.satisfies?(focus, depth: depth + 1)
      rescue ShEx::NotSatisfied => e
        return satisfy focus: focus, satisfied: e.expression.unsatisfied, depth: depth
      end
      not_satisfied "Expression should not have matched",
        focus: focus, unsatisfied: satisfied_op, depth: depth
    end

    def json_type
      "ShapeNot"
    end
  end
end
