module ShEx::Algebra
  ##
  class Not < Operator::Unary
    include Satisfiable
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
    # @param  (see Satisfiable#satisfies?)
    # @return (see Satisfiable#satisfies?)
    # @raise  (see Satisfiable#satisfies?)
    # @see [https://shexspec.github.io/spec/#shape-expression-semantics]
    def satisfies?(focus)
      status ""
      satisfied_op = begin
        operands.first.satisfies?(focus)
      rescue ShEx::NotSatisfied => e
        return satisfy satisfied: e.expression.unsatisfied
      end
      not_satisfied "Expression should not have matched", unsatisfied: satisfied_op
    end
  end
end
