module ShEx::Algebra
  ##
  class Start < Operator::Unary
    include ShapeExpression
    NAME = :start

    #
    # @param  (see ShapeExpression#satisfies?)
    # @return (see ShapeExpression#satisfies?)
    # @raise  (see ShapeExpression#satisfies?)
    def satisfies?(focus, depth: 0)
      status "", depth: depth
      matched_op = case expression
      when RDF::Resource
        schema.enter_shape(expression, focus) do |shape|
          if shape
            shape.satisfies?(focus, depth: depth + 1)
          else
            status "Satisfy as #{expression} was re-entered for #{focus}", depth: depth
            nil
          end
        end
      when ShapeExpression
        expression.satisfies?(focus, depth: depth + 1)
      end
      satisfy focus: focus, satisfied: matched_op, depth: depth
    rescue ShEx::NotSatisfied => e
      not_satisfied e.message, focus: focus, unsatisfied: e.expression, depth: depth
      raise
    end

    ##
    # expression must be a ShapeExpression
    #
    # @return [Operator] `self`
    # @raise  [ShEx::StructureError] if the value is invalid
    def validate!
      case expression
      when ShapeExpression
      when RDF::Resource
        ref = schema.find(expression)
        ref.is_a?(ShapeExpression) ||
        structure_error("#{json_type} must reference a ShapeExpression: #{ref}")
      else
        structure_error("#{json_type} must reference a ShapeExpression: #{ref}")
      end
      super
    end
  end
end
