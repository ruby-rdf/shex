require 'rdf'

# Add `referenced` accessor to statement
class RDF::Statement
  # @return [ShEx::Algebra::Satisfiable] referenced operand which satisfied some of this statement
  attr_accessor :referenced
end
