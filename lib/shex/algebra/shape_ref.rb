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
    # @param  (see Satisfiable#satisfies?)
    # @return (see Satisfiable#satisfies?)
    # @raise  (see Satisfiable#satisfies?)
    # @see [https://shexspec.github.io/spec/#shape-expression-semantics]
    def satisfies?(focus)
      status "ref #{operands.first.to_s}"
      schema.enter_shape(operands.first, focus) do |shape|
        if shape
          matched_shape = shape.satisfies?(focus)
          satisfy focus: focus, satisfied: matched_shape
        else
          status "Satisfy as #{operands.first} was re-entered for #{focus}"
          satisfy focus: focus, satisfied: referenced_shape
        end
      end
    rescue ShEx::NotSatisfied => e
      not_satisfied e.message, focus: focus, unsatisfied: e.expression
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

    ##
    # Returns the binary S-Expression (SXP) representation of this operator.
    #
    # @return [Array]
    # @see    https://en.wikipedia.org/wiki/S-expression
    def to_sxp_bin
      operator = [self.class.const_get(:NAME)].flatten.first
      [:shapeRef, operands.first].to_sxp_bin
    end
  end
end
