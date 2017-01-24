module ShEx::Algebra
  ##
  class Inclusion < Operator
    include TripleExpression
    NAME = :inclusion

    ##
    # Creates an operator instance from a parsed ShExJ representation
    # @param (see Operator#from_shexj)
    # @return [Operator]
    def self.from_shexj(operator, options = {})
      raise ArgumentError unless operator.is_a?(Hash) && operator['type'] == "Inclusion"
      raise ArgumentError, "missing include in #{operator.inspect}" unless operator.has_key?('include')
      super
    end

    def initialize(arg, **options)
      raise ArgumentError, "Shape inclusion must be an IRI or BNode: #{arg}" unless arg.is_a?(RDF::Resource)
      super
    end

    ##
    # In this case, we accept an array of statements, and match based on cardinality.
    #
    # @param  (see TripleExpression#matches)
    # @return (see TripleExpression#matches)
    # @raise  (see TripleExpression#matches)
    def matches(arcs_in, arcs_out, depth: 0)
      status "reference: #{operands.first}"
      expression = referenced_expression
      max = maximum
      matched_expression = expression.matches(arcs_in, arcs_out, depth: depth + 1)
      satisfy matched: matched_expression.matched, depth: depth
    rescue ShEx::NotMatched => e
      not_matched e.message, unsatisfied: e.expression, depth: depth
    end

    ##
    # Returns the referenced shape
    #
    # @return [Operand]
    def referenced_expression
      @referenced_expression ||= begin
        ref = schema.find(operands.first)
        ref = ref.expression if ref.is_a?(ShapeExpression) && ref.respond_to?(:expression)
        ref
      end
    end

    ##
    # A Inclusion is valid if it's ancestor schema has any shape with a lable
    # the same as it's reference.
    #
    # An Inclusion object's include property must appear in the schema's shapes map and the corresponding triple expression must be a Shape with a tripleExpr. The function dereference(include) returns the shape's tripleExpr.
    def validate!
      structure_error("Missing included shape: #{operands.first}") if referenced_expression.nil?
      structure_error("Self included expression: #{operands.first}") if referenced_expression == self
      structure_error("Reference must be an Expression: #{operands.first}") unless referenced_expression.is_a?(TripleExpression)
      super
    end

    ##
    # Returns the binary S-Expression (SXP) representation of this operator.
    #
    # @return [Array]
    # @see    https://en.wikipedia.org/wiki/S-expression
    def to_sxp_bin
      ([:inclusion, ([:id, @id] if @id)].compact + operands).to_sxp_bin
    end
  end
end
