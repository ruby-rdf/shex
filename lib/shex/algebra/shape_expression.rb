require 'sparql/algebra'

module ShEx::Algebra
  # Implements `satisfies?` and `not_satisfies?`
  module ShapeExpression
    ##
    # Satisfies method
    # @param [RDF::Resource] focus
    # @param [Integer] depth for logging
    # @param [Hash{Symbol => Object}] options
    #   Other, operand-specific options
    # @return [ShapeExpression] with `matched` and `satisfied` accessors for matched triples and sub-expressions
    # @raise [ShEx::NotMatched] with `expression` accessor to access `matched` and `unmatched` statements along with `satisfied` and `unsatisfied` operations.
    # @see [http://shex.io/shex-semantics/#shape-expression-semantics]
    def satisfies?(focus, depth: 0, **options)
      raise NotImplementedError, "#satisfies? Not implemented in #{self.class}"
    end

    ##
    # expressions must be ShapeExpressions or references.
    #
    # @return [Operator] `self`
    # @raise  [ShEx::StructureError] if the value is invalid
    def validate_expressions!
      expressions.each do |op|
        case op
        when ShapeExpression
        when RDF::Resource
          ref = schema.find(op)
          ref.is_a?(ShapeExpression) ||
          structure_error("#{json_type} must reference a ShapeExpression: #{ref}")
        else
          structure_error("#{json_type} must be a ShapeExpression or reference: #{op.to_sxp}")
        end
      end
    end
  end
end
