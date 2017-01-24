module ShEx::Algebra
  ##
  class ShapeRef < Operator::Unary
    include ShapeExpression
    NAME = :shapeRef

    def initialize(arg, **options)
      structure_error("Shape reference must be an IRI or BNode: #{arg}", exception: ArgumentError) unless arg.is_a?(RDF::Resource)
      super
    end

    ##
    # Creates an operator instance from a parsed ShExJ representation
    # @param (see Operator#from_shexj)
    # @return [Operator]
    def self.from_shexj(operator, options = {})
      raise ArgumentError unless operator.is_a?(Hash) && operator['type'] == "ShapeRef"
      raise ArgumentError, "missing reference in #{operator.inspect}" unless operator.has_key?('reference')
      super
    end

    ##
    # Satisfies referenced shape.
    # @param  (see ShapeExpression#satisfies?)
    # @return (see ShapeExpression#satisfies?)
    # @raise  (see ShapeExpression#satisfies?)
    # @see [https://shexspec.github.io/spec/#shape-expression-semantics]
    def satisfies?(focus, depth: 0)
      status "ref #{operands.first.to_s}", depth: depth
      schema.enter_shape(operands.first, focus) do |shape|
        if shape
          matched_shape = shape.satisfies?(focus, depth: depth + 1)
          satisfy focus: focus, satisfied: matched_shape, depth: depth
        else
          status "Satisfy as #{operands.first} was re-entered for #{focus}", depth: depth
          satisfy focus: focus, satisfied: referenced_shape, depth: depth
        end
      end
    rescue ShEx::NotSatisfied => e
      not_satisfied e.message, focus: focus, unsatisfied: e.expression, depth: depth
    end

    ##
    # Returns the referenced shape
    #
    # @return [Shape]
    def referenced_shape
      @referenced_shape ||= schema.shapes.detect {|s| s.id == operands.first}
    end

    ##
    # A ShapeRef is valid if it's ancestor schema has any shape with a id
    # the same as it's reference.
    # A ref cannot reference itself (via whatever path) without going through a TripleConstraint.
    # Even when going through TripleConstraints, there can't be a negative reference.
    def validate!
      structure_error("Missing referenced shape: #{operands.first}") if referenced_shape.nil?
      raise ShEx::StructureError, "Self referencing shape: #{operands.first}" if referenced_shape == first_ancestor(ShapeExpression)
      super
    end

    ##
    # Returns the binary S-Expression (SXP) representation of this operator.
    #
    # @return [Array]
    # @see    https://en.wikipedia.org/wiki/S-expression
    def to_sxp_bin
      ([:shapeRef, ([:id, @id] if @id)].compact + operands).to_sxp_bin
    end
  end
end
