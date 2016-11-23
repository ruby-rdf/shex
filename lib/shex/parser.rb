require 'ebnf'
require 'ebnf/ll1/parser'
require 'shex/meta'

module ShEx
  ##
  # A parser for the ShEx grammar.
  #
  # @see https://www.w3.org/2005/01/yacker/uploads/ShEx3?lang=perl&markup=html#productions
  # @see http://en.wikipedia.org/wiki/LR_parser
  class Parser
    include ShEx::Meta
    include ShEx::Terminals
    include EBNF::LL1::Parser

    ##
    # Any additional options for the parser.
    #
    # @return [Hash]
    attr_reader   :options

    ##
    # The current input string being processed.
    #
    # @return [String]
    attr_accessor :input

    ##
    # The current input tokens being processed.
    #
    # @return [Array<Token>]
    attr_reader   :tokens

    ##
    # The internal representation of the result using hierarchy of RDF objects and ShEx::Operator
    # objects.
    # @return [Array]
    # @see http://sparql.rubyforge.org/algebra
    attr_accessor :result

    # Terminals passed to lexer. Order matters!
    terminal(:CODE,                 CODE) do |prod, token, input|
      input[:CODE] = token.value
    end
    terminal(:REPEAT_RANGE,         REPEAT_RANGE) do |prod, token, input|
      input[:cardinality] = token.value
    end
    terminal(:ANON,                 ANON) do |prod, token, input|
      input[:BlankNode] = bnode
    end
    terminal(:BLANK_NODE_LABEL,     BLANK_NODE_LABEL) do |prod, token, input|
      input[:BlankNode] = bnode(token.value[2..-1])
    end
    terminal(:IRIREF,               IRIREF, unescape: true) do |prod, token, input|
      begin
        input[:iri] = iri(token.value[1..-2])
      rescue ArgumentError => e
        raise Error, e.message
      end
    end
    terminal(:DOUBLE,               DOUBLE) do |prod, token, input|
      # Note that a Turtle Double may begin with a '.[eE]', so tack on a leading
      # zero if necessary
      value = token.value.sub(/\.([eE])/, '.0\1')
      input[:literal] = literal(value, datatype: RDF::XSD.double)
    end
    terminal(:DECIMAL,              DECIMAL) do |prod, token, input|
      # Note that a Turtle Decimal may begin with a '.', so tack on a leading
      # zero if necessary
      value = token.value
      #value = "0#{token.value}" if token.value[0,1] == "."
      input[:literal] = literal(value, datatype: RDF::XSD.decimal)
    end
    terminal(:INTEGER,              INTEGER) do |prod, token, input|
      input[:literal] = literal(token.value, datatype: RDF::XSD.integer)
    end
    terminal(:LANGTAG,              LANGTAG) do |prod, token, input|
      add_prod_datum(:language, token.value[1..-1])
    end
    terminal(:PNAME_LN,             PNAME_LN, unescape: true) do |prod, token, input|
      prefix, suffix = token.value.split(":", 2)
      input[:iri] = ns(prefix, suffix)
    end
    terminal(:PNAME_NS,             PNAME_NS) do |prod, token, input|
      prefix = token.value[0..-2]
      # [68] PrefixedName ::= PNAME_LN | PNAME_NS
      input[:iri] = ns(prefix, nil)
      input[:prefix] = prefix && prefix.to_sym
    end
    terminal(:ATPNAME_LN,             ATPNAME_LN, unescape: true) do |prod, token, input|
      prefix, suffix = token.value[1..-1].split(":", 2)
      input[:iri] = ns(prefix, suffix)
    end
    terminal(:ATPNAME_NS,             ATPNAME_NS) do |prod, token, input|
      prefix = token.value[1..-2]
      # [68] PrefixedName ::= PNAME_LN | PNAME_NS
      input[:iri] = ns(prefix, nil)
      input[:prefix] = prefix && prefix.to_sym
    end
    terminal(:STRING_LITERAL_LONG1, STRING_LITERAL_LONG1, unescape: true) do |prod, token, input|
      input[:string] = token.value[3..-4]
    end
    terminal(:STRING_LITERAL_LONG2, STRING_LITERAL_LONG2, unescape: true) do |prod, token, input|
      input[:string] = token.value[3..-4]
    end
    terminal(:STRING_LITERAL1,      STRING_LITERAL1, unescape: true) do |prod, token, input|
      input[:string] = token.value[1..-2]
    end
    terminal(:STRING_LITERAL2,      STRING_LITERAL2, unescape: true) do |prod, token, input|
      input[:string] = token.value[1..-2]
    end

    # String terminals
    terminal(nil, STR_EXPR) do |prod, token, input|
      case token.value
      when '*', '+', '?'   then input[:cardinality] = token.value
      when '^', '|'        then (input[:senseFlags] ||= "") << token.value
      when 'true', 'false' then input[:literal] = RDF::Literal::Boolean.new(token.value)
      when 'a'             then input[:predicate] = (a = RDF.type.dup; a.lexical = 'a'; a)
      else
        #add_prod_datum(:string, token.value)
      end
    end

    # Mixed-case Keyword terminals
    terminal(nil, MC_EXPR, map: MC_MAP) do |prod, token, input|
      case token.value
      when 'not'           then input[:negShapeAtom] = token.value
      when 'external'      then add_prod_datum(:shape, token.value)
      when 'closed'        then add_prod_datum(:shapeDefinition, token.value)
      when 'iri', 'bnode',
           'nonliteral'    then input[:nonLiteralKind] = token.value
      when 'length',
           'minlength',
           'maxlength'    then input[:stringLength] = token.value
      when 'mininclusive',
           'minexclusive',
           'maxinclusive',
           'maxexclusive' then input[:stringLength] = token.value
      when 'fractiondigits',
           'totaldigits'   then input[:numericLength] = token.value
      else
        #add_prod_datum(:string, token.value)
      end
    end

    # Productions
    # [2]  	Query	  ::=  	Prologue
    #                     ( SelectQuery | ConstructQuery | DescribeQuery | AskQuery )
    production(:Query) do |input, data, callback|
      query = data[:query].first

      # Add prefix
      if data[:PrefixDecl]
        pfx = data[:PrefixDecl].shift
        data[:PrefixDecl].each {|p| pfx.merge!(p)}
        pfx.operands[1] = query
        query = pfx
      end

      # Add base
      query = SPARQL::Algebra::Expression[:base, data[:BaseDecl].first, query] if data[:BaseDecl]

      add_prod_datum(:query, query)
    end

    ##
    # Initializes a new parser instance.
    #
    # @param  [String, IO, StringIO, #to_s]          input
    # @param  [Hash{Symbol => Object}] options
    # @option options [Hash]     :prefixes     (Hash.new)
    #   the prefix mappings to use (for acessing intermediate parser productions)
    # @option options [#to_s]    :base_uri     (nil)
    #   the base URI to use when resolving relative URIs (for acessing intermediate parser productions)
    # @option options [#to_s]    :anon_base     ("b0")
    #   Basis for generating anonymous Nodes
    # @option options [Boolean] :resolve_iris (false)
    #   Resolve prefix and relative IRIs, otherwise, when serializing the parsed SSE
    #   as S-Expressions, use the original prefixed and relative URIs along with `base` and `prefix`
    #   definitions.
    # @option options [Boolean]  :validate     (false)
    #   whether to validate the parsed statements and values
    # @option options [Boolean] :progress
    #   Show progress of parser productions
    # @option options [Boolean] :debug
    #   Detailed debug output
    # @yield  [parser] `self`
    # @yieldparam  [ShEx::Parser] parser
    # @yieldreturn [void] ignored
    # @return [ShEx::Parser]
    def initialize(input = nil, options = {}, &block)
      @input = case input
      when IO, StringIO then input.read
      else input.to_s.dup
      end
      @input.encode!(Encoding::UTF_8) if @input.respond_to?(:encode!)
      @options = {anon_base: "b0", validate: false}.merge(options)
      @options[:debug] ||= case
      when options[:progress] then 2
      when options[:validate] then 1
      end

      debug("base IRI") {base_uri.inspect}
      debug("validate") {validate?.inspect}

      @vars = {}
      @nd_var_gen = "0"

      if block_given?
        case block.arity
          when 0 then instance_eval(&block)
          else block.call(self)
        end
      end
    end

    ##
    # Returns `true` if the input string is syntactically valid.
    #
    # @return [Boolean]
    def valid?
      parse
      true
    rescue Error
      false
    end

    # @return [String]
    def to_sxp_bin
      @result
    end

    def to_s
      @result.to_sxp
    end

    alias_method :ll1_parse, :parse

    # Parse query
    #
    # The result is a SPARQL Algebra S-List. Productions return an array such as the following:
    #
    #   (prefix ((: <http://example/>))
    #     (union
    #       (bgp (triple ?s ?p ?o))
    #       (graph ?g
    #         (bgp (triple ?s ?p ?o)))))
    #
    # @param [Symbol, #to_s] prod The starting production for the parser.
    #   It may be a URI from the grammar, or a symbol representing the local_name portion of the grammar URI.
    # @return [Array]
    # @see http://www.w3.org/TR/sparql11-query/#sparqlAlgebra
    # @see http://axel.deri.ie/sparqltutorial/ESWC2007_SPARQL_Tutorial_unit2b.pdf
    def parse(prod = START)
      ll1_parse(@input, prod.to_sym, @options.merge(branch: BRANCH,
                                                    first: FIRST,
                                                    follow: FOLLOW,
                                                    whitespace: WS)
      ) do |context, *data|
        case context
        when :trace
          level, lineno, depth, *args = data
          message = args.to_sse
          d_str = depth > 100 ? ' ' * 100 + '+' : ' ' * depth
          str = "[#{lineno}](#{level})#{d_str}#{message}".chop
          case @options[:debug]
          when Array
            @options[:debug] << str unless level > 2
          when TrueClass
            $stderr.puts str
          when Integer
            $stderr.puts(str) if level <= @options[:debug]
          end
        end
      end

      # The last thing on the @prod_data stack is the result
      @result = case
      when !prod_data.is_a?(Hash)
        prod_data
      when prod_data.empty?
        nil
      when prod_data[:query]
        Array(prod_data[:query]).length == 1 ? prod_data[:query].first : prod_data[:query]
      when prod_data[:update]
        prod_data[:update]
      else
        key = prod_data.keys.first
        [key] + Array(prod_data[key])  # Creates [:key, [:triple], ...]
      end

      # Validate resulting expression
      @result.validate! if @result && validate?
      @result
    end

    private
    ##
    # Returns the URI prefixes currently defined for this parser.
    #
    # @example
    #   prefixes[:dc]  #=> RDF::URI('http://purl.org/dc/terms/')
    #
    # @return [Hash{Symbol => RDF::URI}]
    # @since  0.3.0
    def prefixes
      @options[:prefixes] ||= {}
    end

    ##
    # Defines the given URI prefixes for this parser.
    #
    # @example
    #   prefixes = {
    #     dc: RDF::URI('http://purl.org/dc/terms/'),
    #   }
    #
    # @param  [Hash{Symbol => RDF::URI}] prefixes
    # @return [Hash{Symbol => RDF::URI}]
    # @since  0.3.0
    def prefixes=(prefixes)
      @options[:prefixes] = prefixes
    end

    ##
    # Defines the given named URI prefix for this parser.
    #
    # @example Defining a URI prefix
    #   prefix :dc, RDF::URI('http://purl.org/dc/terms/')
    #
    # @example Returning a URI prefix
    #   prefix(:dc)    #=> RDF::URI('http://purl.org/dc/terms/')
    #
    # @overload prefix(name, uri)
    #   @param  [Symbol, #to_s]   name
    #   @param  [RDF::URI, #to_s] uri
    #
    # @overload prefix(name)
    #   @param  [Symbol, #to_s]   name
    #
    # @return [RDF::URI]
    def prefix(name, iri = nil)
      name = name.to_s.empty? ? nil : (name.respond_to?(:to_sym) ? name.to_sym : name.to_s.to_sym)
      iri.nil? ? prefixes[name] : prefixes[name] = iri
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
      RDF::URI(@options[:base_uri])
    end

    ##
    # Set the Base URI to use for this parser.
    #
    # @param  [RDF::URI, #to_s] iri
    #
    # @example
    #   base_uri = RDF::URI('http://purl.org/dc/terms/')
    #
    # @return [RDF::URI]
    def base_uri=(iri)
      @options[:base_uri] = RDF::URI(iri)
    end

    ##
    # Returns `true` if parsed statements and values should be validated.
    #
    # @return [Boolean] `true` or `false`
    # @since  0.3.0
    def resolve_iris?
      @options[:resolve_iris]
    end

    ##
    # Returns `true` when resolving IRIs, otherwise BASE and PREFIX are retained in the output algebra.
    #
    # @return [Boolean] `true` or `false`
    # @since  1.0.3
    def validate?
      @options[:validate]
    end

    # Used for generating BNode labels
    attr_accessor :nd_var_gen

    # Generate BNodes, not non-distinguished variables
    # @param [Boolean] value
    # @return [void]
    def gen_bnodes(value = true)
      @nd_var_gen = value ? false : "0"
    end

    # Clear cached BNodes
    # @return [void]
    def clear_bnode_cache
      @bnode_cache = {}
    end

    # Freeze BNodes, which allows us to detect if they're re-used
    # @return [void]
    def freeze_bnodes
      @bnode_cache ||= {}
      @bnode_cache.each_value(&:freeze)
    end

    # Generate a BNode identifier
    def bnode(id = nil)
      if @nd_var_gen
        # Use non-distinguished variables within patterns
        variable(id, false)
      else
        unless id
          id = @options[:anon_base]
          @options[:anon_base] = @options[:anon_base].succ
        end
        @bnode_cache ||= {}
        raise Error, "Illegal attempt to reuse a BNode" if @bnode_cache[id] && @bnode_cache[id].frozen?
        @bnode_cache[id] ||= RDF::Node.new(id)
      end
    end

    ##
    # Return variable allocated to an ID.
    # If no ID is provided, a new variable
    # is allocated. Otherwise, any previous assignment will be used.
    #
    # The variable has a #distinguished? method applied depending on if this
    # is a disinguished or non-distinguished variable. Non-distinguished
    # variables are effectively the same as BNodes.
    # @return [RDF::Query::Variable]
    def variable(id, distinguished = true)
      id = nil if id.to_s.empty?

      if id
        @vars[id] ||= begin
          v = RDF::Query::Variable.new(id)
          v.distinguished = distinguished
          v
        end
      else
        unless distinguished
          # Allocate a non-distinguished variable identifier
          id = @nd_var_gen
          @nd_var_gen = id.succ
        end
        v = RDF::Query::Variable.new(id)
        v.distinguished = distinguished
        v
      end
    end

    # Create URIs
    def iri(value)
      # If we have a base URI, use that when constructing a new URI
      value = RDF::URI(value)
      if base_uri && value.relative?
        u = base_uri.join(value)
        u.lexical = "<#{value}>" unless resolve_iris?
        u
      else
        value
      end
    end

    def ns(prefix, suffix)
      base = prefix(prefix).to_s
      suffix = suffix.to_s.sub(/^\#/, "") if base.index("#")
      debug {"ns(#{prefix.inspect}): base: '#{base}', suffix: '#{suffix}'"}
      iri = iri(base + suffix.to_s)
      # Cause URI to be serialized as a lexical
      iri.lexical = "#{prefix}:#{suffix}" unless resolve_iris?
      iri
    end

    # Create a literal
    def literal(value, options = {})
      options = options.dup
      # Internal representation is to not use xsd:string, although it could arguably go the other way.
      options.delete(:datatype) if options[:datatype] == RDF::XSD.string
      debug("literal") do
        "value: #{value.inspect}, " +
        "options: #{options.inspect}, " +
        "validate: #{validate?.inspect}, "
      end
      RDF::Literal.new(value, options.merge(validate: validate?))
    end

    # Take collection of objects and create RDF Collection using rdf:first, rdf:rest and rdf:nil
    # @param [Hash] data Production Data
    def expand_collection(data)
      # Add any triples generated from deeper productions
      add_prod_datum(:pattern, data[:pattern])

      # Create list items for each element in data[:GraphNode]
      first = data[:Collection]
      list = Array(data[:GraphNode]).flatten.compact
      last = list.pop

      list.each do |r|
        add_pattern(:Collection, subject: first, predicate: RDF["first"], object: r)
        rest = bnode()
        add_pattern(:Collection, subject: first, predicate: RDF["rest"], object: rest)
        first = rest
      end

      if last
        add_pattern(:Collection, subject: first, predicate: RDF["first"], object: last)
      end
      add_pattern(:Collection, subject: first, predicate: RDF["rest"], object: RDF["nil"])
    end

    # add a pattern
    #
    # @param [String] production Production generating pattern
    # @param [Hash{Symbol => Object}] options
    def add_pattern(production, options)
      progress(production, "[:pattern, #{options[:subject]}, #{options[:predicate]}, #{options[:object]}]")
      triple = {}
      options.each_pair do |r, v|
        if v.is_a?(Array) && v.flatten.length == 1
          v = v.flatten.first
        end
        if validate? && !v.is_a?(RDF::Term)
          error("add_pattern", "Expected #{r} to be a resource, but it was #{v.inspect}",
            production: production)
        end
        triple[r] = v
      end
      add_prod_datum(:pattern, RDF::Query::Pattern.new(triple))
    end

    # Flatten a Data in form of filter: [op+ bgp?], without a query into filter and query creating exprlist, if necessary
    # @return [Array[:expr, query]]
    def flatten_filter(data)
      query = data.pop if data.last.is_a?(SPARQL::Algebra::Query)
      expr = data.length > 1 ? SPARQL::Algebra::Operator::Exprlist.new(*data) : data.first
      [expr, query]
    end

    # Merge query modifiers, datasets, and projections
    #
    # This includes tranforming aggregates if also used with a GROUP BY
    #
    # @see http://www.w3.org/TR/sparql11-query/#convertGroupAggSelectExpressions
    def merge_modifiers(data)
      debug("merge modifiers") {data.inspect}
      query = data[:query] ? data[:query].first : SPARQL::Algebra::Operator::BGP.new

      vars = data[:Var] || []
      order = data[:order] ? data[:order].first : []
      extensions = data.fetch(:extend, [])
      having = data.fetch(:having, [])
      values = data.fetch(:ValuesClause, []).first

      # extension variables must not appear in projected variables.
      # Add them to the projection otherwise
      extensions.each do |(var, expr)|
        raise Error, "Extension variable #{var} also in SELECT" if vars.map(&:to_s).include?(var.to_s)
        vars << var
      end

      # If any extension contains an aggregate, and there is now group, implicitly group by 1
      if !data[:group] &&
         extensions.any? {|(var, function)| function.aggregate?} ||
         having.any? {|c| c.aggregate? }
        debug {"Implicit group"}
        data[:group] = [[]]
      end

      # Add datasets and modifiers in order
      if data[:group]
        group_vars = data[:group].first

        # For creating temporary variables
        agg = 0

        # Find aggregated varirables in extensions
        aggregates = []
        aggregated_vars = extensions.map do |(var, function)|
          var if function.aggregate?
        end.compact

        # Common function for replacing aggregates with temporary variables,
        # as defined in http://www.w3.org/TR/2013/REC-sparql11-query-20130321/#convertGroupAggSelectExpressions
        aggregate_expression = lambda do |expr|
          # Replace unaggregated variables in expr
          # - For each unaggregated variable V in X
          expr.replace_vars! do |v|
            aggregated_vars.include?(v) ? v : SPARQL::Algebra::Expression[:sample, v]
          end

          # Replace aggregates in expr as above
          expr.replace_aggregate! do |function|
            if avf = aggregates.detect {|(v, f)| f == function}
              avf.first
            else
              # Allocate a temporary variable for this function, and retain the mapping for outside the group
              av = RDF::Query::Variable.new(".#{agg}")
              av.distinguished = false
              agg += 1
              aggregates << [av, function]
              av
            end
          end
        end

        # If there are extensions, they are aggregated if necessary and bound
        # to temporary variables
        extensions.map! do |(var, expr)|
          [var, aggregate_expression.call(expr)]
        end

        # Having clauses
        having.map! do |expr|
          aggregate_expression.call(expr)
        end

        query = if aggregates.empty?
          SPARQL::Algebra::Expression[:group, group_vars, query]
        else
          SPARQL::Algebra::Expression[:group, group_vars, aggregates, query]
        end
      end

      if values
        query = query ? SPARQL::Algebra::Expression[:join, query, values] : values
      end

      query = SPARQL::Algebra::Expression[:extend, extensions, query] unless extensions.empty?

      query = SPARQL::Algebra::Expression[:filter, *having, query] unless having.empty?

      query = SPARQL::Algebra::Expression[:order, data[:order].first, query] unless order.empty?

      query = SPARQL::Algebra::Expression[:project, vars, query] unless vars.empty?

      query = SPARQL::Algebra::Expression[data[:DISTINCT_REDUCED], query] if data[:DISTINCT_REDUCED]

      query = SPARQL::Algebra::Expression[:slice, data[:slice][0], data[:slice][1], query] if data[:slice]

      query = SPARQL::Algebra::Expression[:dataset, data[:dataset], query] if data[:dataset]

      query
    end

    # Add joined expressions in for prod1 (op prod2)* to form (op (op 1 2) 3)
    def add_operator_expressions(production, data)
      # Iterate through expression to create binary operations
      lhs = data[:Expression]
      while data[production] && !data[production].empty?
        op, rhs = data[production].shift, data[production].shift
        lhs = SPARQL::Algebra::Expression[op + lhs + rhs]
      end
      add_prod_datum(:Expression, lhs)
    end

    # Accumulate joined expressions in for prod1 (op prod2)* to form (op (op 1 2) 3)
    def accumulate_operator_expressions(operator, production, data)
      if data[operator]
        # Add [op data] to stack based on "production"
        add_prod_datum(production, [data[operator], data[:Expression]])
        # Add previous [op data] information
        add_prod_datum(production, data[production])
      else
        # No operator, forward :Expression
        add_prod_datum(:Expression, data[:Expression])
      end
    end
  end # class Parser
end # module ShEx
