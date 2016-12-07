module ShEx::Algebra
  ##
  class Schema < Operator
    include Satisfiable
    NAME = :schema

    ##
    # Match on schema. Finds appropriate shape for node, and matches that shape.
    #
    # FIXME: startActs and start
    #
    # @param [RDF::Resource] n
    # @param [RDF::Queryable] g
    # @param [Hash{RDF::Resource => RDF::Resource}] m
    # @return [Boolean] `true` if satisfied, `false` if it does not apply
    # @raise [ShEx::NotSatisfied] if not satisfied
    def satisfies?(n, g, m)
      # Make sure they're URIs
      m = m.inject({}) {|memo, (k,v)| memo.merge(k.to_s => v.to_s)}
      label = m[n.to_s]
      raise(ShEx::StructureError, "No shape found for #{n} in #{m}") unless label
      shape = shapes[label]
      raise(ShEx::StructureError, "No shape found for #{label}") unless shape
      shape.satisfies?(n, g, m)
      true
    end

    ##
    # Shapes as a hash
    # @return [Hash{RDF::Resource => Operator}]
    def shapes
      @shapes ||= begin
        shapes = operands.
        detect {|op| op.is_a?(Array) && op.first == :shapes}
        shapes = shapes ? shapes.last : {}
        shapes.inject({}) do |memo, (label, operand)|
          memo.merge(label.to_s => operand)
        end
      end
    end

    ##
    # Enumerate via depth-first recursive descent over operands, yielding each operator
    # @yield operator
    # @yieldparam [Object] operator
    # @return [Enumerator]
    def each_descendant(&block)
      if block_given?
        super(&block)
        shapes.values.each do |op|
          op.each_descendant(&block) if op.respond_to?(:each_descendant)
          block.call(op)
        end
      end
      enum_for(:each_descendant)
    end

    ##
    # Validate shapes, in addition to other operands
    # @return [SPARQL::Algebra::Expression] `self`
    # @raise  [ArgumentError] if the value is invalid
    def validate!
      shapes.values.each {|op| op.validate! if op.respond_to?(:validate!)}
      super
    end
  end
end
