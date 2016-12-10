module ShEx::Algebra
  ##
  class Schema < Operator
    include Satisfiable
    NAME = :schema

    # Graph to validate
    # @return [RDF::Queryable]
    attr_accessor :graph

    # Map of nodes to shapes
    # @return [Hash{RDF::Resource => RDF::Resource}]
    attr_reader :map

    ##
    # Match on schema. Finds appropriate shape for node, and matches that shape.
    #
    # @param [RDF::Resource] n
    # @param [RDF::Queryable] g
    # @param [Hash{RDF::Resource => RDF::Resource}] m
    # @param [Array<Schema, String>] shapeExterns ([])
    #   One or more schemas, or paths to ShEx schema resources used for finding external shapes.
    # @return [Boolean] `true` if satisfied, `false` if it does not apply
    # @raise [ShEx::NotSatisfied] if not satisfied
    # FIXME: set of node/shape pairs
    def satisfies?(n, g, m, shapeExterns: [], **options)
      @graph = g
      @external_schemas = shapeExterns
      # Make sure they're URIs
      @map = m.inject({}) {|memo, (k,v)| memo.merge(k.to_s => v.to_s)}

      # First, evaluate semantic acts
      operands.select {|o| o.is_a?(SemAct)}.all? do |op|
        op.satisfies?([])
      end

      # Next run any start expression
      if start
        status("start") {"expression: #{start.to_sxp}"}
        start.satisfies?(n)
      end

      label = @map[n.to_s]
      if label && !label.empty?
        shape = shapes[label]
        structure_error("No shape found for #{label}") unless shape

        # If `n` is a Blank Node, we won't find it through normal matching, find an equivalent node in the graph having the same label
        if n.is_a?(RDF::Node)
          nn = graph.enum_term.detect {|t| t.id == n.id}
          n = nn if nn
        end

        shape.satisfies?(n)
      end
      status "schema satisfied"
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
    # Externally loaded schemas, lazily evaluated
    # @return [Array<Schema>]
    def external_schemas
      @external_schemas = Array(@external_schemas).map do |extern|
        schema = case extern
        when Schema then extern
        else
          status "Load extern #{extern}"
          ShEx.open(extern, logger: options[:logger])
        end
        schema.graph = graph
        schema
      end
    end

    ##
    # Enumerate via depth-first recursive descent over operands, yielding each operator
    # @yield operator
    # @yieldparam [Object] operator
    # @return [Enumerator]
    def each_descendant(depth = 0, &block)
      if block_given?
        super(depth + 1, &block)
        shapes.values.each do |op|
          op.each_descendant(depth + 1, &block) if op.respond_to?(:each_descendant)

          case block.arity
          when 1 then block.call(op)
          else block.call(depth, op)
          end
        end
      end
      enum_for(:each_descendant)
    end

    ##
    # Start action, if any
    def start
      @start ||= operands.detect {|op| op.is_a?(Start)}
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
