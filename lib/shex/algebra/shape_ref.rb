module ShEx::Algebra
  ##
  class ShapeRef < Operator::Unary
    NAME = :shapeRef

    def initialize(arg, **options)
      raise ShEx::OperandError, "Shape reference must be an IRI or BNode: #{arg}" unless arg.is_a?(RDF::Resource)
      super
    end

    ##
    def evaluate(bindings, options = {})
    end

    ##
    # Returns the referenced shape
    #
    # @return [Shape]
    def referenced_shape
      @shape ||= begin
        schema = first_ancestor(Schema)
        schema.operands.detect do |op|
          (op.is_a?(Shape) || op.is_a?(ShapeExternal)) && op.operands.first == operands.first
        end
      end
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
