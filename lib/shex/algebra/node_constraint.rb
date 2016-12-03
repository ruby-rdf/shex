module ShEx::Algebra
  ##
  class NodeConstraint < Operator
    include Satisfiable
    NAME = :nodeConstraint

    #
    # S is a NodeConstraint and satisfies2(n, se) as described below in Node Constraints. Note that testing if a node satisfies a node constraint does not require a graph or shapeMap.
    def satisfies(n, g, m)
      satisfies2(n)
    end

    ##
    # Satisfies2 checks a particular node (value) against this constraint
    # @return [Boolean]
    def satisfies2(value)
      satisfies_node_kind?(value) ||
      satisfies_datatype?(value) ||
      satisfies_string_facet?(value) ||
      satisfies_numeric_facet?(value) ||
      satisfies_values?(value)
    rescue NotSatisfied
      return false
    end
  private

    ##
    # Satisfies Node Kind Constraint
    # @return [Boolean]
    # @raise [NotSatisfied] if not the right node kind
    def satisfies_node_kind?(value)
      kind = case operands.detect {|op| [:iri, :bnode, :literal, :nonliteral].include?(op)}
      when :iri         then RDF::URI
      when :bnode       then RDF::Node
      when :literal     then RDF::Literal
      when :nonliteral  then RDF::Resource
      else              return false
      end

      raise NotSatisfied unless value.is_a?(kind)
      true
    end

    ##
    # Datatype Constraint
    # @return [Boolean]
    # @raise [NotSatisfied] if not the right node kind
    def satisfies_datatype?(value)      
      dt = op_fetch(:datatype)
      return false unless dt

      raise NotSatisfied unless value.is_a?(Literal) && value.datatype == RDF::URI(dt)
      true
    end

    ##
    # String Facet Constraint
    # Checks all length/minlength/maxlength/pattern facets against the string representation of the value.
    # @return [Boolean]
    # @raise [NotSatisfied] if not the right node kind
    def satisfies_string_facet?(value)
      length    = op_fetch(:length)
      minlength = op_fetch(:minlength)
      maxlength = op_fetch(:maxlength)
      pattern   = op_fetch(:pattern)

      v_s = value.to_s
      raise NotSatisfied if length && v_s.length != length
      raise NotSatisfied if minlength && v_s.length < minlength
      raise NotSatisfied if maxlength && v_s.length > maxlength
      raise NotSatisfied if pattern && !Regexp.new(pattern).match(v_s)
      true
    end

    ##
    # Numeric Facet Constraint
    # Checks all numeric facets against the value.
    # @return [Boolean]
    # @raise [NotSatisfied] if not the right node kind
    def satisfies_numeric_facet?(value)
      mininclusive   = op_fetch(:mininclusive)
      minexclusive   = op_fetch(:minexclusive)
      maxinclusive   = op_fetch(:maxinclusive)
      maxexclusive   = op_fetch(:maxexclusive)
      totaldigits    = op_fetch(:totaldigits)
      fractiondigits = op_fetch(:fractiondigits)

      return false if (mininclusive || minexclusive || maxinclusive || maxexclusive || totaldigits || fractiondigits).nil?

      raise NotSatisfied unless value.is_a?(RDF::Literal::Numeric)

      raise NotSatisfied unless (totaldigits || fractionaldigits).nil? || value.is_a?(RDF::Literal::Decimal)

      case
      when !mininclusive.nil? && value < mininclusive then raise NotSatisfied
      when !minexclusive.nil? && value <= minexclusive then raise NotSatisfied
      when !maxinclusive.nil? && value > maxinclusive then raise NotSatisfied
      when !maxexclusive.nil? && value >= maxexclusive then raise NotSatisfied
      when !totaldigits.nil? && value.dup.canonicalize!.to_s.length != totaldigits
        raise NotSatisfied
      when !fractiondigits.nil? && value.dup.canonicalize!.to_s.length != fractiondigits
        raise NotSatisfied
      end
      true
    end

    ##
    # Value Constraint
    # Checks all numeric facets against the value.
    # @return [Boolean]
    # @raise [NotSatisfied] if not the right node kind
    def satisfies_values?(value)
      raise NotImplemented
    end

    # Returns the value of a particular facet
    def op_fetch(which)
      operands.detect {|op| op[1] if op.is_a?(Array) && op[0] == which}
    end

    class NotSatisfied < Exception; end
  end
end
