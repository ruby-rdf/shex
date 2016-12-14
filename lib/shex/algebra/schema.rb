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
    # Match on schema. Finds appropriate shape for node, and matches that shape.
    #
    # @param [RDF::Resource] focus
    # @param [RDF::Queryable] graph
    # @param [Hash{RDF::Resource => RDF::Resource}] map
    # @param [Array<Schema, String>] shapeExterns ([])
    #   One or more schemas, or paths to ShEx schema resources used for finding external shapes.
    # @return [true, Operand] returns operand containing matched/unmatched and satisfied/unsatisfied for operands if not satisfied, `true` otherwise.
    # @raise [ShEx::NotSatisfied] if not satisfied
    # FIXME: set of node/shape pairs
    def execute(focus, graph, map, shapeExterns: [], **options)
      satisfies?(focus, graph, map, options.merge(shapeExterns: shapeExterns))
    rescue ShEx::NotSatisfied => e
      e.expression
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
    # @return [Boolean] `true` if `focus` is satisfied by this schema in `graph`
    # @raise [ShEx::NotSatisfied] if not satisfied
    # FIXME: set of node/shape pairs
    def satisfies?(focus, graph, map, shapeExterns: [], **options)
      @graph = graph
      @external_schemas = shapeExterns
      focus = iri(focus)
      # Make sure they're URIs
      @map = (map || {}).inject({}) {|memo, (k,v)| memo.merge(iri(k).to_s => iri(v).to_s)}

      # First, evaluate semantic acts
      semantic_actions.all? do |op|
        op.satisfies?([])
      end

      # Next run any start expression
      if start
        status("start") {"expression: #{start.to_sxp}"}
        start.satisfies?(focus)
      end

      label = @map[focus.to_s]
      if label && !label.empty?
        shape = shapes[label]
        structure_error("No shape found for #{label}") unless shape

        # If `n` is a Blank Node, we won't find it through normal matching, find an equivalent node in the graph having the same label
        if focus.is_a?(RDF::Node)
          n = graph.enum_term.detect {|t| t.id == focus.id}
          focus = n if n
        end

        shape.satisfies?(focus)
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
    # Returns the Base URI defined for the parser,
    # as specified or when parsing a BASE prologue element.
    #
    # @example
    #   base  #=> RDF::URI('http://example.com/')
    #
    # @return [HRDF::URI]
    def base_uri
      RDF::URI(@options[:base_uri]) if @options[:base_uri]
    end

    # Create URIs
    def iri(value)
      # If we have a base URI, use that when constructing a new URI
      case value
      when RDF::Value then value
      when /^_:/ then RDF::Node(value[2..-1].to_s)
      else
        value = RDF::URI(value)
        if base_uri && value.relative?
          base_uri.join(value)
        else
          value
        end
      end
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
