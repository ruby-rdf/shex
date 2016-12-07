module ShEx::Algebra
  ##
  class NodeConstraint < Operator
    include Satisfiable
    NAME = :nodeConstraint

    #
    # S is a NodeConstraint and satisfies2(n, se) as described below in Node Constraints. Note that testing if a node satisfies a node constraint does not require a graph or shapeMap.
    # @param [RDF::Resource] n
    # @param [RDF::Queryable] g
    # @param [Hash{RDF::Resource => RDF::Resource}] m
    # @return [Boolean] `true` if satisfied, `false` if it does not apply
    # @raise [ShEx::NotSatisfied] if not satisfied
    def satisfies?(n, g, m)
      satisfies_node_kind?(n) ||
      satisfies_datatype?(n) ||
      satisfies_string_facet?(n) ||
      satisfies_numeric_facet?(n) ||
      satisfies_values?(n)
    end

  private

    ##
    # Satisfies Node Kind Constraint
    # @return [Boolean] `true` if satisfied, `false` if it does not apply
    # @raise [ShEx::NotSatisfied] if not satisfied
    def satisfies_node_kind?(value)
      kind = case operands.first
      when :iri         then RDF::URI
      when :bnode       then RDF::Node
      when :literal     then RDF::Literal
      when :nonliteral  then RDF::Resource
      else              return false
      end

      raise(ShEx::NotSatisfied, "Node was #{value.inspect} expected kind #{kind}") unless
        value.is_a?(kind)
      true
    end

    ##
    # Datatype Constraint
    # @return [Boolean] `true` if satisfied, `false` if it does not apply
    # @raise [ShEx::NotSatisfied] if not satisfied
    def satisfies_datatype?(value)      
      dt = operands[1] if operands.first == :datatype
      return false unless dt

      raise(ShEx::NotSatisfied, "Node was #{value.inspect}, expected datatype #{dt}") unless
        value.is_a?(RDF::Literal) && value.datatype == RDF::URI(dt)
      true
    end

    ##
    # String Facet Constraint
    # Checks all length/minlength/maxlength/pattern facets against the string representation of the value.
    # @return [Boolean] `true` if satisfied, `false` if it does not apply
    # @raise [ShEx::NotSatisfied] if not satisfied
    def satisfies_string_facet?(value)
      length    = op_fetch(:length)
      minlength = op_fetch(:minlength)
      maxlength = op_fetch(:maxlength)
      pattern   = op_fetch(:pattern)

      return false if (length || minlength || maxlength || pattern).nil?

      v_s = value.to_s
      raise(ShEx::NotSatisfied, "Node #{v_s.inspect} length not #{length}") if
        length && v_s.length != length.to_i
      raise(ShEx::NotSatisfied, "Node #{v_s.inspect} length < #{minlength}") if
        minlength && v_s.length < minlength.to_i
      raise(ShEx::NotSatisfied, "Node #{v_s.inspect} length > #{maxlength}") if
        maxlength && v_s.length > maxlength.to_i
      raise(ShEx::NotSatisfied, "Node #{v_s.inspect} does not match #{pattern}") if
        pattern && !Regexp.new(pattern).match(v_s)
      true
    end

    ##
    # Numeric Facet Constraint
    # Checks all numeric facets against the value.
    # @return [Boolean] `true` if satisfied, `false` if it does not apply
    # @raise [ShEx::NotSatisfied] if not satisfied
    def satisfies_numeric_facet?(value)
      mininclusive   = op_fetch(:mininclusive)
      minexclusive   = op_fetch(:minexclusive)
      maxinclusive   = op_fetch(:maxinclusive)
      maxexclusive   = op_fetch(:maxexclusive)
      totaldigits    = op_fetch(:totaldigits)
      fractiondigits = op_fetch(:fractiondigits)

      return false if (mininclusive || minexclusive || maxinclusive || maxexclusive || totaldigits || fractiondigits).nil?

      raise(ShEx::NotSatisfied, "Node #{value.inspect} not numeric") unless
        value.is_a?(RDF::Literal::Numeric)

      raise(ShEx::NotSatisfied, "Node #{value.inspect} not decimal") if
        (totaldigits || fractiondigits) && !value.is_a?(RDF::Literal::Decimal)

      numeric_value = value.object
      case
      when !mininclusive.nil? && numeric_value < mininclusive.object then raise(ShEx::NotSatisfied, "Node #{value.inspect} < #{mininclusive.object}")
      when !minexclusive.nil? && numeric_value <= minexclusive.object then raise(ShEx::NotSatisfied, "Node #{value.inspect} not <= #{minexclusive.object}")
      when !maxinclusive.nil? && numeric_value > maxinclusive.object then raise(ShEx::NotSatisfied, "Node #{value.inspect} > #{maxinclusive.object}")
      when !maxexclusive.nil? && numeric_value >= maxexclusive.object then raise(ShEx::NotSatisfied, "Node #{value.inspect} >= #{maxexclusive.object}")
      when !totaldigits.nil? && value.dup.canonicalize!.to_s.length != totaldigits.to_i
        raise(ShEx::NotSatisfied, "Node #{value.inspect} total digits != #{totaldigits}")
      when !fractiondigits.nil? && value.dup.canonicalize!.to_s.length != fractiondigits.to_i
        raise(ShEx::NotSatisfied, "Node #{value.inspect} fractional digits != #{fractiondigits}")
      end
      true
    end

    ##
    # Value Constraint
    # Checks all numeric facets against the value.
    # @return [Boolean] `true` if satisfied, `false` if it does not apply
    # @raise [ShEx::NotSatisfied] if not satisfied
    def satisfies_values?(value)
      values = operands.select {|op| op.is_a?(Value)}
      return false if values.empty?
      matched_value = values.detect {|v| v.match?(value)}
      raise(ShEx::NotSatisfied, "Node #{value.inspect} not expected") unless matched_value
      true
    end

    # Returns the value of a particular facet
    def op_fetch(which)
      (operands.detect {|op| op.is_a?(Array) && op[0] == which} || [])[1]
    end
  end
end
