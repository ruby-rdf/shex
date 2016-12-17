module ShEx::Algebra
  ##
  class And < Operator
    include Satisfiable
    NAME = :and

    def initialize(*args, **options)
      case
      when args.length <= 1
        raise ArgumentError, "wrong number of arguments (given #{args.length}, expected 1..)"
      end
      super
    end

    ##
    # Creates an operator instance from a parsed ShExJ representation
    # @param (see Operator#from_shexj)
    # @return [Operator]
    def self.from_shexj(operator, options = {})
      raise ArgumentError unless operator.is_a?(Hash) && operator['type'] == 'ShapeAnd'
      raise ArgumentError, "missing shapeExprs in #{operator.inspect}" unless operator.has_key?('shapeExprs')
      super
    end

    #
    # S is a ShapeAnd and for every shape expression se2 in shapeExprs, satisfies(n, se2, G, m).
    # @param  (see Satisfiable#satisfies?)
    # @return (see Satisfiable#satisfies?)
    # @raise  (see Satisfiable#satisfies?)
    def satisfies?(focus)
      status ""
      expressions = operands.select {|o| o.is_a?(Satisfiable)}
      satisfied = []

      # Operand raises NotSatisfied, so no need to check here.
      expressions.each do |op|
        satisfied << op.satisfies?(focus)
      end
      satisfy satisfied: satisfied
    rescue ShEx::NotSatisfied => e
      not_satisfied e.message,
                    satisfied:   satisfied,
                    unsatisfied: (expressions - satisfied)
    end
  end
end
