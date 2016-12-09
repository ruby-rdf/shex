$:.unshift(File.expand_path("../..", __FILE__))
require 'sparql/algebra'
require 'sxp'
require 'shex/algebra/extensions'

module ShEx
  # Based on the SPARQL Algebra, operators for executing a patch
  #
  # @author [Gregg Kellogg](http://greggkellogg.net/)
  module Algebra
    autoload :And, 'shex/algebra/and'
    autoload :Annotation, 'shex/algebra/annotation'
    autoload :Base, 'shex/algebra/base'
    autoload :EachOf, 'shex/algebra/each_of'
    autoload :Inclusion, 'shex/algebra/inclusion'
    autoload :Not, 'shex/algebra/not'
    autoload :NodeConstraint, 'shex/algebra/node_constraint'
    autoload :OneOf, 'shex/algebra/one_of'
    autoload :Operator, 'shex/algebra/operator'
    autoload :Or, 'shex/algebra/or'
    autoload :Prefix, 'shex/algebra/prefix'
    autoload :Satisfiable, 'shex/algebra/satisfiable'
    autoload :Schema, 'shex/algebra/schema'
    autoload :SemAct, 'shex/algebra/semact'
    autoload :ShapeExternal, 'shex/algebra/shape_external'
    autoload :ShapeRef, 'shex/algebra/shape_ref'
    autoload :Shape, 'shex/algebra/shape'
    autoload :Start, 'shex/algebra/start'
    autoload :Stem, 'shex/algebra/stem'
    autoload :StemRange, 'shex/algebra/stem_range'
    autoload :TripleConstraint, 'shex/algebra/triple_constraint'
    autoload :TripleExpression, 'shex/algebra/triple_expression'
    autoload :UnaryShape, 'shex/algebra/unary_shape'
    autoload :Value, 'shex/algebra/value'

    class NotMatched < ShEx::Error; end
  end
end


