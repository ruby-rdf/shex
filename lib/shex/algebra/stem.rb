module ShEx::Algebra
  ##
  class Stem < Operator::Unary
    NAME = :stem

    ##
    # Creates an operator instance from a parsed ShExJ representation
    # @param (see Operator#from_shexj)
    # @return [Operator]
    def self.from_shexj(operator, options = {})
      raise ArgumentError unless operator.is_a?(Hash) && operator['type'] == "Stem"
      raise ArgumentError, "missing stem in #{operator.inspect}" unless operator.has_key?('stem')
      super
    end

    ##
    # For a node n and constraint value v, nodeSatisfies(n, v) if n matches some valueSetValue vsv in v. A term matches a valueSetValue if:
    #
    # * vsv is a Stem with stem st and nodeIn(n, st).
    def match?(value)
      if value.start_with?(operands.first)
        status "matched #{value}"
        true
      else
        status "not matched #{value}"
        false
      end
    end

    def json_type
      # FIXME: This is funky, due to oddities in normative shexj
      parent.is_a?(Value) ? 'StemRange' : 'Stem'
    end
  end
end
