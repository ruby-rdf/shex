module ShEx::Algebra
  ##
  class Schema < Operator
    NAME = :schema

    ##
    # Shapes as a hash
    # @return [Hash{RDF::Resource => Operator}]
    def shapes
      @shapes ||= begin
        shapes = operands.
        detect {|op| op.is_a?(Array) && op.first == :shapes}
        shapes = shapes ? shapes.last : {}
        shapes.inject({}) do |memo, (label, operand)|
          memo.merge(label => operand)
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
