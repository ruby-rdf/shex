module ShEx::Algebra
  ##
  class ShapeRef < Operator::Unary
    include Satisfiable
    NAME = :shapeRef

    def initialize(arg, **options)
      structure_error("Shape reference must be an IRI or BNode: #{arg}", exception: ArgumentError) unless arg.is_a?(RDF::Resource)
      super
    end

    ##
    # Satisfies method
    # @param [RDF::Resource] focus
    # @return [Boolean] `true` if satisfied
    # @raise [ShEx::NotSatisfied] if not satisfied
    # @see [https://shexspec.github.io/spec/#shape-expression-semantics]
    def satisfies?(focus)
      status "ref #{operands.first.to_s}"
      referenced_shape.satisfies?(focus)
      status "ref satisfied"
      true
    rescue ShEx::NotSatisfied => e
      not_satisfied e.message
      raise
    end

    ##
    # Returns the referenced shape
    #
    # @return [Shape]
    def referenced_shape
      schema.shapes[operands.first.to_s]
    end

    ##
    # A ShapeRef is valid if it's ancestor schema has any shape with a lable
    # the same as it's reference.
    def validate!
      structure_error("Missing referenced shape: #{operands.first}") if referenced_shape.nil?
      # FIXME
      #raise ShEx::ParseError, "Self referencing shape: #{operands.first}" if referenced_shape == first_ancestor(Shape)
      super
    end
  end
end
