module ShEx::Algebra
  ##
  class StemRange < Operator::Binary
    NAME = :stemRange

    ##
    # Creates an operator instance from a parsed ShExJ representation
    # @param (see Operator#from_shexj)
    # @return [Operator]
    def self.from_shexj(operator, options = {})
      raise ArgumentError unless operator.is_a?(Hash) && operator['type'] == 'StemRange'
      raise ArgumentError, "missing stem in #{operator.inspect}" unless operator.has_key?('stem')

      # Normalize wildcard representation
      operator['stem'] = :wildcard if operator['stem'] =={'type' => 'Wildcard'}

      # Note that the type may be StemRange, but if there's no exclusions, it's really just a Stem
      if operator.has_key?('exclusions')
        super
      else
        Stem.from_shexj(operator.merge('type' => 'Stem'), options)
      end
    end

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

      unless initial_match
        status "#{value} does not match #{operands.first}"
        return false
      end

      if exclusions.any? do |exclusion|
          case exclusion
          when RDF::Value then value == exclusion
          when Stem       then exclusion.match?(value)
          else                 false
          end
        end
        status "#{value} excluded"
        return false
      end

      status "matched #{value}"
      true
    end

    def exclusions
      (operands.last.is_a?(Array) && operands.last.first == :exclusions) ? operands.last[1..-1] : []
    end
  end
end
