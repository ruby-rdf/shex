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

    # Map of Semantic Action instances
    # @return [Hash{String => ShEx::Extension}]
    attr_reader :extensions

    ##
    # Creates an operator instance from a parsed ShExJ representation
    # @param (see Operator#from_shexj)
    # @return [Operator]
    def self.from_shexj(operator, options = {})
      raise ArgumentError unless operator.is_a?(Hash) && operator['type'] == "Schema"
      super
    end

    # (see Operator#initialize)
    def initialize(*operands)
      super
      each_descendant do |op|
        # Set schema everywhere
        op.schema = self
      end
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
    # @option options [String] :base_uri (for resolving focus)
    # @raise [ShEx::NotSatisfied] along with operand graph described for return
    def execute(focus, graph, map, shapeExterns: [], depth: 0, **options)
      @graph, @shapes_entered = graph, {}
      @external_schemas = shapeExterns
      focus = value(focus, options)

      logger = options[:logger] || @options[:logger]
      each_descendant do |op|
        # Set logging everywhere
        op.logger = logger
      end

      # Initialize Extensions
      @extensions = {}
      each_descendant do |op|
        next unless op.is_a?(SemAct)
        name = op.operands.first.to_s
        if ext_class = ShEx::Extension.find(name)
          @extensions[name] ||= ext_class.new(schema: self, depth: depth, **options)
        end
      end

      # If `n` is a Blank Node, we won't find it through normal matching, find an equivalent node in the graph having the same id
      graph_focus = graph.enum_term.detect {|t| t.node? && t.id == focus.id} if focus.is_a?(RDF::Node)
      graph_focus ||= focus

      # Make sure they're URIs
      @map = (map || {}).inject({}) {|memo, (k,v)| memo.merge(value(k) => iri(v))}

      # First, evaluate semantic acts
      semantic_actions.all? do |op|
        op.satisfies?([], depth: depth + 1)
      end

      # Keep a new Schema, specifically for recording actions
      satisfied_schema = Schema.new
      # Next run any start expression
      if start
        satisfied_schema.operands << start.satisfies?(focus, depth: depth + 1)
      end

      # Add shape result(s)
      satisfied_shapes = {}
      satisfied_schema.operands << [:shapes, satisfied_shapes] unless shapes.empty?

      # Match against all shapes associated with the ids for focus
      Array(@map[focus]).each do |id|
        enter_shape(id, focus) do |shape|
          satisfied_shapes[id] = shape.satisfies?(graph_focus, depth: depth + 1)
        end
      end
      status "schema satisfied", depth: depth
      satisfied_schema
    ensure
      # Close Semantic Action extensions
      @extensions.values.each {|ext| ext.close(schema: self, depth: depth, **options)}
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
    # @param [RDF::Resource] id
    # @param [RDF::Resource] node
    # @yield :shape
    # @yieldparam [ShapeExpression] shape, or `nil` if shape already entered
    # @return (see ShapeExpression#satisfies?)
    # @raise (see ShapeExpression#satisfies?)
    def enter_shape(id, node, &block)
      shape = shapes.detect {|s| s.id == id}
      structure_error("No shape found for #{id}") unless shape
      @shapes_entered[id] ||= {}
      if @shapes_entered[id][node]
        block.call(false)
      else
        @shapes_entered[id][node] = self
        begin
          block.call(shape)
        ensure
          @shapes_entered[id].delete(node)
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
    # Start action, if any
    def start
      @start ||= operands.detect {|op| op.is_a?(Start)}
    end

    ##
    # Find a ShapeExpression or TripleExpression by identifier
    # @param [#to_s] id
    # @return [TripleExpression, ShapeExpression]
    def find(id)
      each_descendant.detect {|op| op.id == id}
    end

    ##
    # Validate shapes, in addition to other operands
    # @return [Operator] `self`
    # @raise  [ArgumentError] if the value is invalid
    def validate!
      shapes.each do |op|
        op.validate! if op.respond_to?(:validate!)
        if op.is_a?(RDF::Resource)
          ref = find(op)
          structure_error("Missing reference: #{op}") if ref.nil?
        end
      end
      super
    end
  end
end
