module ShEx::Algebra
  ##
  class Schema < Operator
    NAME = :schema

    # Graph to validate
    # @return [RDF::Queryable]
    attr_accessor :graph

    # Map of nodes to shapes
    # @return [Hash{RDF::Resource => RDF::Resource}]
    attr_reader :map

    ##
    # Creates an operator instance from a parsed ShExJ representation
    # @param (see Operator#from_shexj)
    # @return [Operator]
    def self.from_shexj(operator, options = {})
      raise ArgumentError unless operator.is_a?(Hash) && operator['type'] == "Schema"
      super
    end

    ##
    # Match on schema. Finds appropriate shape for node, and matches that shape.
    #
    # @param [RDF::Term] focus
    # @param [RDF::Queryable] graph
    # @param [Hash{RDF::Resource => RDF::Resource}] map
    # @param [Array<Schema, String>] shapeExterns ([])
    #   One or more schemas, or paths to ShEx schema resources used for finding external shapes.
    # @return [Operand] Returns operand graph annotated with satisfied and unsatisfied operations.
    # @param [Hash{Symbol => Object}] options
    # @option options [String] :base_uri
    # @raise [ShEx::NotSatisfied] along with operand graph described for return
    def execute(focus, graph, map, shapeExterns: [], **options)
      @graph, @shapes_entered = graph, {}
      @external_schemas = shapeExterns
      focus = value(focus)

      # If `n` is a Blank Node, we won't find it through normal matching, find an equivalent node in the graph having the same label
      graph_focus = graph.enum_term.detect {|t| t.id == focus.id} if focus.is_a?(RDF::Node)
      graph_focus ||= focus

      # Make sure they're URIs
      @map = (map || {}).inject({}) {|memo, (k,v)| memo.merge(value(k) => iri(v))}

      # First, evaluate semantic acts
      semantic_actions.all? do |op|
        op.satisfies?([])
      end

      # Keep a new Schema, specifically for recording actions
      satisfied_schema = Schema.new
      # Next run any start expression
      if start
        status("start") {"expression: #{start.to_sxp}"}
        satisfied_schema.operands << start.satisfies?(focus)
      end

      # Add shape result(s)
      satisfied_shapes = {}
      satisfied_schema.operands << [:shapes, satisfied_shapes] unless shapes.empty?

      # Match against all shapes associated with the labels for focus
      Array(@map[focus]).each do |label|
        enter_shape(label, focus) do |shape|
          satisfied_shapes[label] = shape.satisfies?(graph_focus)
        end
      end
      status "schema satisfied"
      satisfied_schema
    end

    ##
    # Match on schema. Finds appropriate shape for node, and matches that shape.
    #
    # @param [RDF::Resource] focus
    # @param [RDF::Queryable] graph
    # @param [Hash{RDF::Resource => RDF::Resource}] map
    # @param [Array<Schema, String>] shapeExterns ([])
    #   One or more schemas, or paths to ShEx schema resources used for finding external shapes.
    # @param [Hash{Symbol => Object}] options
    # @option options [String] :base_uri
    # @return [Boolean]
    def satisfies?(focus, graph, map, shapeExterns: [], **options)
      execute(focus, graph, map, options.merge(shapeExterns: shapeExterns))
    rescue ShEx::NotSatisfied
      false
    end

    ##
    # Shapes as a hash
    # @return [Array<Operator>]
    def shapes
      @shapes ||= begin
        shapes = Array(operands.detect {|op| op.is_a?(Array) && op.first == :shapes})
        Array(shapes[1..-1])
      end
    end

    ##
    # Indicate that a shape has been entered with a specific focus node. Any future attempt to enter the same shape with the same node raises an exception.
    # @param [RDF::Resource] label
    # @param [RDF::Resource] node
    # @yield :shape
    # @yieldparam [Satisfiable] shape, or `nil` if shape already entered
    # @return [Satisfiable]
    def enter_shape(label, node, &block)
      shape = shapes.detect {|s| s.label == label}
      structure_error("No shape found for #{label}") unless shape
      @shapes_entered[label] ||= {}
      if @shapes_entered[label][node]
        block.call(false)
      else
        @shapes_entered[label][node] = self
        begin
          block.call(shape)
        ensure
          @shapes_entered[label].delete(node)
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
        shapes.each do |op|
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
      shapes.each {|op| op.validate! if op.respond_to?(:validate!)}
      super
    end
  end
end
