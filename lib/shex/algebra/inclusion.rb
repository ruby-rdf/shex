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
      schema.shapes[operands.first.to_s]
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
      log_error("Missing included shape: #{operands.first}", depth: options.fetch(:depth, 0), exception: ShEx::ParseError) {"expression: #{self.to_sxp}"} if referenced_shape.nil?
      log_error("Self included shape: #{operands.first}", depth: options.fetch(:depth, 0), exception: ShEx::ParseError) {"expression: #{self.to_sxp}"} if referenced_shape == first_ancestor(Shape)
      case referenced_shape.operands.first
      when TripleConstraint, Inclusion, EachOf, OneOf
      else
        log_error("Includes non-simple shape: #{operands.first}", depth: options.fetch(:depth, 0), exception: ShEx::ParseError) {"expression: #{self.to_sxp}"}
      end
      super
    end
  end
end
