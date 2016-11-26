$:.unshift(File.expand_path("../..", __FILE__))
require 'sparql/algebra'
require 'sxp'

module ShEx
  # Based on the SPARQL Algebra, operators for executing a patch
  #
  # @author [Gregg Kellogg](http://greggkellogg.net/)
  module Algebra
    autoload :And, 'shex/algebra/and'
    autoload :Base, 'shex/algebra/base'
    autoload :EachOf, 'shex/algebra/each_of'
    autoload :Not, 'shex/algebra/not'
    autoload :NodeConstraint, 'shex/algebra/node_constraint'
    autoload :Operator, 'shex/algebra/operator'
    autoload :Or, 'shex/algebra/or'
    autoload :Prefix, 'shex/algebra/prefix'
    autoload :Schema, 'shex/algebra/schema'
    autoload :ShapeDefinition, 'shex/algebra/shape_definition'
    autoload :ShapeRef, 'shex/algebra/shape_ref'
    autoload :Shape, 'shex/algebra/shape'
    autoload :SomeOf, 'shex/algebra/some_of'
    autoload :TripleConstraint, 'shex/algebra/triple_constraint'
    autoload :UnaryShape, 'shex/algebra/unary_shape'
  end
end

