module ShEx::Algebra
  ##
  class StemRange < Operator::Binary
    NAME = :stemRange

    ##
    # For a node n and constraint value v, nodeSatisfies(n, v) if n matches some valueSetValue vsv in v. A term matches a valueSetValue if:
    #
    # * vsv is a StemRange with stem st and exclusions excls and nodeIn(n, st) and there is no x in excls such that nodeIn(n, excl).
    # * vsv is a Wildcard with exclusions excls and there is no x in excls such that nodeIn(n, excl).
    def match?(value)
      initial_match = case operands.first
      when :wildcard then true
      when RDF::Value then value.start_with?(operands.first)
      else false
      end

      return false unless initial_match

      return false if exclusions.any? do |exclusion|
        case exclusion
        when RDF::Value then value == exclusion
        when Stem then exclusion.match?(value)
        else false
        end
      end

      true
    end

    def exclusions
      (operands.last.is_a?(Array) && operands.last.first == :exclusions) ? operands.last[1..-1] : []
    end
  end
end
