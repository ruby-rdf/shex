module ShEx::Algebra
  ##
  class Or < Operator
    include Satisfiable
    NAME = :or

    def initialize(*args, **options)
      case
      when args.length < 2
        raise ArgumentError, "wrong number of arguments (given #{args.length}, expected 2..)"
      end

      # All arguments must be Satisfiable
      raise ArgumentError, "All operands must be Shape operands" unless args.all? {|o| o.is_a?(Satisfiable)}
      super
    end

    ##
    # Creates an operator instance from a parsed ShExJ representation
    # @param (see Operator#from_shexj)
    # @return [Operator]
    def self.from_shexj(operator, options = {})
      raise ArgumentError unless operator.is_a?(Hash) && operator['type'] == 'ShapeOr'
      raise ArgumentError, "missing shapeExprs in #{operator.inspect}" unless operator.is_a?(Hash) && operator.has_key?('shapeExprs')
      super
    end

    #
    # S is a ShapeOr and there is some shape expression se2 in shapeExprs such that satisfies(n, se2, G, m).
    # @param  (see Satisfiable#satisfies?)
    # @return (see Satisfiable#satisfies?)
    # @raise  (see Satisfiable#satisfies?)
    def satisfies?(focus)
      status ""
      expressions = operands.select {|o| o.is_a?(Satisfiable)}
      unsatisfied = []
      expressions.any? do |op|
        begin
          matched_op = op.satisfies?(focus)
          return satisfy focus: focus, satisfied: matched_op, unsatisfied: unsatisfied
        rescue ShEx::NotSatisfied => e
          status "unsatisfied #{focus}"
          op = op.dup
          op.satisfied = e.expression.satisfied
          op.unsatisfied = e.expression.unsatisfied
          unsatisfied << op
          status("unsatisfied: #{e.message}")
          false
        end
      end

      not_satisfied "Expected some expression to be satisfied",
                    focus: focus, unsatisfied: unsatisfied
    end

    def json_type
      "ShapeOr"
    end
  end
end
