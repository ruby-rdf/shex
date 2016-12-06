module ShEx::Algebra
  ##
  class Inclusion < Operator
    include TripleExpression
    NAME = :inclusion

    def initialize(arg, **options)
      raise ShEx::OperandError, "Shape inclusion must be an IRI or BNode: #{arg}" unless arg.is_a?(RDF::Resource)
      super
    end

    ##
    # Returns the referenced shape
    #
    # @return [Operand]
    def referenced_shape
      schema.shapes[operands.first]
    end

    ##
    # Predicates associated with this TripleExpression
    #
    # FIXME: May need to search through referenced shape.
    #
    # @return [Array<RDF::URI>]
    def predicates
      []
    end

    ##
    # A Inclusion is valid if it's ancestor schema has any shape with a lable
    # the same as it's reference.
    def validate!
      raise ShEx::ParseError, "Missing included shape: #{operands.first}" if referenced_shape.nil?
      raise ShEx::ParseError, "Self included shape: #{operands.first}" if referenced_shape == first_ancestor(Shape)
      case referenced_shape.operands.first
      when TripleConstraint, Inclusion, EachOf, SomeOf
      else
        raise ShEx::ParseError, "Includes non-simple shape: #{operands.first}"
      end
      super
    end
  end
end
