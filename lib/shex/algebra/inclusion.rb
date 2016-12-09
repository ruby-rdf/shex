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
    # In this case, we accept an array of statements, and match based on cardinality.
    #
    # @param [Array<RDF::Statement>] t
    # @return [Array<RDF::Statement>]
    # @raise NotMatched, ShEx::NotSatisfied
    def matches(t)
      status "referenced_shape: #{operands.first}"
      expression = referenced_shape.triple_expressions.first
      max = maximum
      results = expression.matches(t)

      # Max violations handled in Shape
      not_matched "Minimum Cardinality Violation: #{results.length} < #{minimum}" if
        results.length < minimum

      # Last, evaluate semantic acts
      operands.select {|o| o.is_a?(SemAct)}.all? do |op|
        op.satisfies?(results)
      end unless results.empty?

      results
    end

    ##
    # Returns the referenced shape
    #
    # @return [Operand]
    def referenced_shape
      schema.shapes[operands.first.to_s]
    end

    ##
    # A Inclusion is valid if it's ancestor schema has any shape with a lable
    # the same as it's reference.
    #
    # An Inclusion object's include property must appear in the schema's shapes map and the corresponding triple expression must be a Shape with a tripleExpr. The function dereference(include) returns the shape's tripleExpr.
    def validate!
      structure_error("Missing included shape: #{operands.first}") if referenced_shape.nil?
      structure_error("Self included shape: #{operands.first}") if referenced_shape == first_ancestor(Shape)

      triple_expressions = referenced_shape.triple_expressions
      case triple_expressions.length
      when 0
        structure_error("Includes shape with no triple expressions")
      when 1
      else
        structure_error("Includes shape with multiple triple expressions")
      end
      super
    end
  end
end
