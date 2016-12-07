module ShEx::Algebra
  ##
  class ShapeRef < Operator::Unary
    include Satisfiable
    NAME = :shapeRef

    def initialize(arg, **options)
      raise ShEx::OperandError, "Shape reference must be an IRI or BNode: #{arg}" unless arg.is_a?(RDF::Resource)
      super
    end

    ##
    # Satisfies method
    # @param [RDF::Resource] n
    # @param [RDF::Queryable] g
    # @param [Hash{RDF::Resource => RDF::Resource}] m
    # @return [Boolean] `true` if satisfied, `false` if it does not apply
    # @raise [ShEx::NotSatisfied] if not satisfied
    # @see [https://shexspec.github.io/spec/#shape-expression-semantics]
    def satisfies?(n, g, m)
      referenced_shape.satisfies?(n, g, m)
    end

    ##
    # Returns the referenced shape
    #
    # @return [Shape]
    def referenced_shape
      schema.shapes[operands.first]
    end

    ##
    # A ShapeRef is valid if it's ancestor schema has any shape with a lable
    # the same as it's reference.
    def validate!
      raise ShEx::ParseError, "Missing referenced shape: #{operands.first}" if referenced_shape.nil?
      #raise ShEx::ParseError, "Self referencing shape: #{operands.first}" if referenced_shape == first_ancestor(Shape)
      super
    end
  end
end
