module ShEx::Algebra
  ##
  class Stem < Operator::Unary
    NAME = :stem

    ##
    # For a node n and constraint value v, nodeSatisfies(n, v) if n matches some valueSetValue vsv in v. A term matches a valueSetValue if:
    #
    # * vsv is a Stem with stem st and nodeIn(n, st).
    def match?(value)
      value.start_with?(operands.first)
    end
  end
end
