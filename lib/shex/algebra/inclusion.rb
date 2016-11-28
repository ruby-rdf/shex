module ShEx::Algebra
  ##
  class Inclusion < Operator
    NAME = :inclusion

    def initialize(arg, **options)
      raise ShEx::OperandError, "Shape inclusion must be an IRI or BNode: #{arg}" unless arg.is_a?(RDF::Resource)
      super
    end

    ##
    # Returns a logical `AND` of all operands
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
    # A Inclusion is valid if it's ancestor schema has any shape with a lable
    # the same as it's reference.
    def validate!
      raise ShEx::ParseError, "Missing included shape: #{operands.first}" if referenced_shape.nil?
      raise ShEx::ParseError, "Self included shape: #{operands.first}" if referenced_shape == first_ancestor(Shape)
      case referenced_shape.operand(1)
      when TripleConstraint, Inclusion, EachOf, SomeOf
      else
        raise ShEx::ParseError, "Includes non-simple shape: #{operand(1)}"
      end
      super
    end
  end
end
