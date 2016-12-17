$:.unshift(File.expand_path("../..", __FILE__))
require 'sparql/algebra'
require 'sxp'

module ShEx
  # Based on the SPARQL Algebra, operators for executing a patch
  #
  # @author [Gregg Kellogg](http://greggkellogg.net/)
  module Algebra
    autoload :And, 'shex/algebra/and'
    autoload :Annotation, 'shex/algebra/annotation'
    autoload :EachOf, 'shex/algebra/each_of'
    autoload :Inclusion, 'shex/algebra/inclusion'
    autoload :Not, 'shex/algebra/not'
    autoload :NodeConstraint, 'shex/algebra/node_constraint'
    autoload :OneOf, 'shex/algebra/one_of'
    autoload :Operator, 'shex/algebra/operator'
    autoload :Or, 'shex/algebra/or'
    autoload :Satisfiable, 'shex/algebra/satisfiable'
    autoload :Schema, 'shex/algebra/schema'
    autoload :SemAct, 'shex/algebra/semact'
    autoload :External, 'shex/algebra/external'
    autoload :ShapeRef, 'shex/algebra/shape_ref'
    autoload :Shape, 'shex/algebra/shape'
    autoload :Start, 'shex/algebra/start'
    autoload :Stem, 'shex/algebra/stem'
    autoload :StemRange, 'shex/algebra/stem_range'
    autoload :TripleConstraint, 'shex/algebra/triple_constraint'
    autoload :TripleExpression, 'shex/algebra/triple_expression'
    autoload :Value, 'shex/algebra/value'


    ##
    # Creates an operator instance from a parsed ShExJ representation
    #
    # @example Simple TripleConstraint
    #   rep = JSON.parse(%({
    #           "type": "TripleConstraint",
    #           "predicate": "http://www.w3.org/1999/02/22-rdf-syntax-ns#type"
    #         }
    #   ))
    #   TripleConstraint.from(rep) #=> (tripleConstraint a)
    # @param [Hash] representation
    # @param [Hash] options ({})
    # @option options [RDF::URI] :base
    # @option options [Hash{String => RDF::URI}] :prefixes
    # @return [Operator]
    def self.from_shexj(operator, options = {})
      raise ArgumentError unless operator.is_a?(Hash)
      klass = case operator['type']
      when 'Annotation'       then Annotation
      when 'EachOf'           then EachOf
      when 'Inclusion'        then Inclusion
      when 'NodeConstraint'   then NodeConstraint
      when 'OneOf'            then OneOf
      when 'Schema'           then Schema
      when 'SemAct'           then SemAct
      when 'Shape'            then Shape
      when 'ShapeAnd'         then And
      when 'ShapeNot'         then Not
      when 'ShapeOr'          then Or
      when 'ShapeRef'         then ShapeRef
      when 'Stem'             then Stem
      when 'StemRange'        then StemRange
      when 'TripleConstraint' then TripleConstraint
      when 'Wildcard'         then StemRange
      else raise ArgumentError, "unknown type #{operator['type']}"
      end

      klass.from_shexj(operator, options)
    end
  end
end


