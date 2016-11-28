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
    terminal(:CODE,                 CODE, unescape: true) do |prod, token, input|
      # { foo %}
      # Keep surrounding whitespace for now
      input[:code] = token.value[1..-2].sub(/%\s*$/, '')  # Drop {} and %
    end
    terminal(:REPEAT_RANGE,         REPEAT_RANGE) do |prod, token, input|
      card = token.value[1..-2].split(',').map {|v| v =~ /^\d+$/ ? v.to_i : v}
      card[1] = token.value.include?(',') ? '*' : card[0] if card.length == 1
      input[:cardinality] = {min: card[0], max: card[1]}
    end
    terminal(:RDF_TYPE,             RDF_TYPE) do |prod, token, input|
      input[:iri] = (a = RDF.type.dup; a.lexical = 'a'; a)
    end
    terminal(:BLANK_NODE_LABEL,     BLANK_NODE_LABEL) do |prod, token, input|
      input[:blankNode] = bnode(token.value[2..-1])
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
    terminal(:PNAME_LN,             PNAME_LN, unescape: true) do |prod, token, input|
      prefix, suffix = token.value.split(":", 2)
      input[:iri] = ns(prefix, suffix)
    end
    terminal(:PNAME_NS,             PNAME_NS) do |prod, token, input|
      prefix = token.value[0..-2]

      input[:iri] = ns(prefix, nil)
      input[:prefix] = prefix && prefix.to_sym
    end
    terminal(:ATPNAME_LN,             ATPNAME_LN, unescape: true) do |prod, token, input|
      prefix, suffix = token.value.split(":", 2)
      prefix.sub!(/^@\s*/, '')
      input[:iri] = ns(prefix, suffix)
    end
    terminal(:ATPNAME_NS,             ATPNAME_NS) do |prod, token, input|
      prefix = token.value[1..-2]

      input[:iri] = ns(prefix, nil)
      input[:prefix] = prefix && prefix.to_sym
    end
    terminal(:LANGTAG,              LANGTAG) do |prod, token, input|
      add_prod_datum(:language, token.value[1..-1])
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
    terminal(nil, STR_EXPR, map: STR_MAP) do |prod, token, input|
      case token.value
      when '*'             then input[:cardinality] = {min: 0, max: "*"}
      when '+'             then input[:cardinality] = {min: 1, max: "*"}
      when '?'             then input[:cardinality] = {min: 0, max: 1}
      when '!'             then input[:not] = token.value
      when '^'             then input[:inverse] = token.value
      when '.'             then input[:dot] = token.value
      when 'true', 'false' then input[:literal] = RDF::Literal::Boolean.new(token.value)
      when '~'             then input[:pattern] = token.value
      when 'BNODE', 'IRI',
           'NONLITERAL'    then input[:nonLiteralKind] = token.value.downcase.to_sym
      when 'CLOSED'        then input[:closed] = token.value.downcase.to_sym
      when 'EXTERNAL'      then input[:external] = token.value.downcase.to_sym
      when 'FRACTIONDIGITS',
           'TOTALDIGITS'   then input[:numericLength] = token.value.downcase.to_sym
      when 'LITERAL'       then input[:shapeAtomLiteral] = token.value.downcase.to_sym
      when 'LENGTH',
           'MINLENGTH',
           'MAXLENGTH'     then input[:stringLength] = token.value.downcase.to_sym
      when 'MININCLUSIVE',
           'MINEXCLUSIVE',
           'MAXINCLUSIVE',
           'MAXEXCLUSIVE'  then input[:numericRange] = token.value.downcase.to_sym
         when 'NOT'           then input[:not] = token.value.downcase.to_sym
      when 'PATTERN'       then input[:pattern] = token.value.downcase.to_sym
      when 'START'         then input[:start] = token.value.downcase.to_sym
      else
        #raise "Unexpected MC terminal: #{token.inspect}"
      end
    end

    # Productions
    # [1]     shexDoc               ::= directive* ((notStartAction | startActions) statement*)?
    production(:shexDoc) do |input, data, callback|
      data[:start][1] = Algebra::Shape.new(data[:start][1]) if data[:start] && !data[:expressions]

      expressions = []
      expressions << [:base, data[:baseDecl]] if data[:baseDecl]
      expressions << [:prefix, data[:prefixDecl]] if data[:prefixDecl]
      expressions += Array(data[:codeDecl])
      expressions << data[:start] if data[:start]
      expressions += Array(data[:expressions])

      input[:schema] = Algebra::Schema.new(*expressions)
    end

    # [2]     directive             ::= baseDecl | prefixDecl

    # [3]     baseDecl              ::= "BASE" IRIREF
    production(:baseDecl) do |input, data, callback|
      input[:baseDecl] = self.base_uri = iri(data[:iri])
    end

    # [4]     prefixDecl            ::= "PREFIX" PNAME_NS IRIREF
    production(:prefixDecl) do |input, data, callback|
      pfx = data[:prefix]
      self.prefix(pfx, data[:iri])
      (input[:prefixDecl] ||= []) << [pfx.to_s, data[:iri]]
    end

    # [5]     notStartAction        ::= start | shapeExprDecl
    # [6]     start                 ::= "start" '=' shapeExpression
    production(:start) do |input, data, callback|
      input[:start] = [:start, data[:shapeExpression]]
    end
    # [7]     startActions          ::= codeDecl+

    # [8]     statement             ::= directive | notStartAction

    # [9]     shapeExprDecl         ::= shapeLabel (shapeExpression|"EXTERNAL")
    production(:shapeExprDecl) do |input, data, callback|
      label = Array(data[:shapeLabel]).first
      expression = data[:shapeExpression]
      attrs = [label, expression]
      attrs << data[:extraPropertySet] if data[:extraPropertySet]
      attrs << :closed if data[:closed]
      attrs += Array(data[:codeDecl])
      shape = if data[:external]
        Algebra::ShapeExternal.new(*attrs.compact)
      else
        Algebra::Shape.new(*attrs.compact)
      end

      (input[:expressions] ||= []) << shape
    end

    # [10]    shapeExpression       ::= shapeOr
    # [11]    inlineShapeExpression ::= inlineShapeOr

    # [12]    shapeOr               ::= shapeAnd ("OR" shapeAnd)*
    production(:shapeOr) do |input, data, callback|
      shape_or(input, data)
    end
    # [13]    inlineShapeOr         ::= inlineShapeAnd ("OR" inlineShapeAnd)*
    production(:inlineShapeOr) do |input, data, callback|
      shape_or(input, data)
    end
    def shape_or(input, data)
      input.merge!(data.dup.keep_if {|k, v| [:closed, :extraPropertySet, :codeDecl].include?(k)})
      expression = if Array(data[:shapeExpression]).length > 1
        Algebra::Or.new(*data[:shapeExpression])
      else
        Array(data[:shapeExpression]).first
      end
      input[:shapeExpression] = expression if expression
    end
    private :shape_or

    # [14]    shapeAnd              ::= shapeNot ("AND" shapeNot)*
    production(:shapeAnd) do |input, data, callback|
      shape_and(input, data)
    end
    # [15]    inlineShapeAnd        ::= inlineShapeNot ("AND" inlineShapeNot)*
    production(:inlineShapeAnd) do |input, data, callback|
      shape_and(input, data)
    end
    def shape_and(input, data)
      input.merge!(data.dup.keep_if {|k, v| [:closed, :extraPropertySet, :codeDecl].include?(k)})
      expressions = Array(data[:shapeExpression]).inject([]) do |memo, expr|
        memo.concat(expr.is_a?(Algebra::And) ? expr.operands : [expr])
      end
      expression = if expressions.length > 1
        Algebra::And.new(*expressions)
      else
        expressions.first
      end
      (input[:shapeExpression] ||= []) << expression if expression
    end
    private :shape_and

    # [16]    shapeNot              ::= "NOT"? shapeAtom
    production(:shapeNot) do |input, data, callback|
      shape_not(input, data)
    end
    # [17]    inlineShapeNot        ::= "NOT"? inlineShapeAtom
    production(:inlineShapeNot) do |input, data, callback|
      shape_not(input, data)
    end
    def shape_not(input, data)
      input.merge!(data.dup.keep_if {|k, v| [:closed, :extraPropertySet, :codeDecl].include?(k)})
      expression = data[:shapeExpression]
      expression = Algebra::Not.new(expression) if data[:not]
      (input[:shapeExpression] ||= []) << expression
    end
    private :shape_not

    # [18]    shapeAtom             ::= nodeConstraint shapeOrRef?
    #                                 | shapeOrRef
    #                                 | "(" shapeExpression ")"
    #                                 | '.'  # no constraint
    production(:shapeAtom) do |input, data, callback|
      shape_atom(input, data)
    end
    # [19]    inlineShapeAtom       ::= nodeConstraint inlineShapeOrRef?
    #                                 | inlineShapeOrRef nodeConstraint?
    #                                 | "(" shapeExpression ")"
    #                                 | '.'  # no constraint
    production(:inlineShapeAtom) do |input, data, callback|
      shape_atom(input, data)
    end
    def shape_atom(input, data)
      constraint = data[:nodeConstraint]
      shape = data[:shapeOrRef]
      input.merge!(data.dup.keep_if {|k, v| [:closed, :extraPropertySet, :codeDecl].include?(k)})

      expression = [constraint, shape].compact
      expression = case expression.length
      when 0 then nil
      when 1
         expression.first
      else   Algebra::And.new(*expression)
      end

      input[:shapeExpression] = expression if expression
    end
    private :shape_atom

    # [20]    shapeOrRef            ::= ATPNAME_LN | ATPNAME_NS | '@' shapeLabel | shapeDefinition
    production(:shapeOrRef) do |input, data, callback|
      shape_or_ref(input, data)
    end
    # [21]    inlineShapeOrRef      ::= ATPNAME_LN | ATPNAME_NS | '@' shapeLabel | inlineShapeDefinition
    production(:inlineShapeOrRef) do |input, data, callback|
      shape_or_ref(input, data)
    end
    def shape_or_ref(input, data)
      input.merge!(data.dup.keep_if {|k, v| [:closed, :extraPropertySet, :codeDecl].include?(k)})
      if data[:iri] || data[:shape] || Array(data[:shapeLabel]).first
        input[:shapeOrRef] = data[:shape] || Algebra::ShapeRef.new(data[:iri] || Array(data[:shapeLabel]).first)
      end
    end
    private :shape_or_ref

    # [22]    nodeConstraint        ::= "LITERAL" xsFacet*
    #                                 | nonLiteralKind stringFacet*
    #                                 | datatype xsFacet*
    #                                 | valueSet xsFacet*
    #                                 | xsFacet+
    production(:nodeConstraint) do |input, data, callback|
      attrs = []
      attrs += [:datatype, data[:datatype]] if data [:datatype]
      attrs += [data[:shapeAtomLiteral], data[:nonLiteralKind]]
      attrs += Array(data[:valueSetValue])
      attrs += Array(data[:xsFacet])
      attrs += Array(data[:stringFacet])

      input[:nodeConstraint] = Algebra::NodeConstraint.new(*attrs.compact)
    end

    # [23]    nonLiteralKind        ::= "IRI" | "BNODE" | "NONLITERAL"

    # [24]    xsFacet               ::= stringFacet | numericFacet
    production(:xsFacet) do |input, data, callback|
      (input[:xsFacet] ||= []) << (Array(data[:stringFacet]).first || data[:numericFacet])
    end

    # [25]    stringFacet           ::= stringLength INTEGER
    #                                 | "PATTERN" string
    #                                 | '~' string  # shortcut for "PATTERN"
    production(:stringFacet) do |input, data, callback|
      input[:stringFacet] ||= []
      input[:stringFacet] << [data[:stringLength], data[:literal]] if data[:stringLength]
      input[:stringFacet] << [:pattern, data[:string]] if data[:pattern]
    end

    # [26]    stringLength          ::= "LENGTH" | "MINLENGTH" | "MAXLENGTH"

    # [27]    numericFacet          ::= numericRange (numericLiteral | string '^^' datatype )
    #                                 | numericLength INTEGER
    production(:numericFacet) do |input, data, callback|
      input[:numericFacet] = if data[:numericRange]
        literal = data[:literal] || literal(data[:string], datatype: data[:datatype])
        [data[:numericRange], literal]
      elsif data[:numericLength]
        [data[:numericLength], data[:literal]]
      end
    end

    # [28]    numericRange          ::= "MININCLUSIVE" | "MINEXCLUSIVE" | "MAXINCLUSIVE" | "MAXEXCLUSIVE"
    # [29]    numericLength         ::= "TOTALDIGITS" | "FRACTIONDIGITS"

    # [30]    shapeDefinition       ::= (extraPropertySet | "CLOSED")* '{' tripleExpression? '}' annotation* semanticActions
    #production(:shapeDefinition) do |input, data, callback|
    #  shape_definition(input, data)
    #end
    ## [31]    inlineShapeDefinition ::= (extraPropertySet | "CLOSED")* '{' tripleExpression? '}'
    #production(:inlineShapeDefinition) do |input, data, callback|
    #  shape_definition(input, data)
    #end
    #def shape_definition(input, data)
    #  shape = data[:shape]
    #  attrs = [
    #    data[:extraPropertySet],
    #    (:closed if data[:closed]),
    #  ].compact
    #  attrs += Array(data[:annotation])
    #  attrs += Array(data[:codeDecl])
    #  shape = Algebra::Shape.new(shape, *attrs) if shape && !attrs.empty?
    #
    #  input[:shape] = shape if shape
    #end
    #private :shape_definition

    # [32]     extraPropertySet       ::= "EXTRA" predicate+
    production(:extraPropertySet) do |input, data, callback|
      input[:extraPropertySet] = data[:predicate].unshift(:extra)
    end

    # [33]    tripleExpression      ::= someOfTripleExpr
    # [34]    someOfTripleExpr           ::= groupTripleExpr ('|' groupTripleExpr)*
    production(:someOfTripleExpr) do |input, data, callback|
      expression = if Array(data[:shape]).length > 1
        Algebra::SomeOf.new(*data[:shape])
      else
        Array(data[:shape]).first
      end
      input[:shape] = expression if expression
    end

    # [37]    groupTripleExpr            ::= unaryTripleExpr (';' unaryTripleExpr?)*
    production(:groupTripleExpr) do |input, data, callback|
      expression = if Array(data[:shape]).length > 1
        Algebra::EachOf.new(*data[:shape])
      else
        Array(data[:shape]).first
      end
      (input[:shape] ||= []) << expression if expression
    end

    # [40]    unaryTripleExpr            ::= productionLabel? (tripleConstraint | bracketedTripleExpr) | include
    production(:unaryTripleExpr) do |input, data, callback|
      shape = data[:tripleConstraint] || data[:bracketedTripleExpr] || data[:include]
      shape.operands << data[:productionLabel] if shape && data[:productionLabel]

      (input[:shape] ||= []) << shape if shape
    end

    # [41]    bracketedTripleExpr   ::= '(' someOfTripleExpr ')' cardinality? annotation* semanticActions
    production(:bracketedTripleExpr) do |input, data, callback|
      # XXX cardinality? annotation* semanticActions
      shape = data[:shape]
      cardinality = data.fetch(:cardinality, {})
      attrs = [
        ([:min, cardinality[:min]] if cardinality[:min]),
        ([:max, cardinality[:max]] if cardinality[:max])
      ].compact
      attrs += Array(data[:codeDecl])
      attrs += Array(data[:annotation])

      shape.operands.concat(attrs)
      input[:bracketedTripleExpr] = shape
    end

    # [42]    productionLabel       ::= '$' (iri | blankNode)
    production(:productionLabel) do |input, data, callback|
      input[:productionLabel] = datea[:iri] || data[:blankNode]
    end

    # [43]    tripleConstraint      ::= senseFlags? predicate shapeExpression cardinality? annotation* semanticActions
    production(:tripleConstraint) do |input, data, callback|
      cardinality = data.fetch(:cardinality, {})
      attrs = [
        (:inverse if data[:inverse] || data[:not]),
        Array(data[:predicate]).first,  # predicate
        data[:shapeExpression],
        ([:min, cardinality[:min]] if cardinality[:min]),
        ([:max, cardinality[:max]] if cardinality[:max])
      ].compact
      attrs += Array(data[:codeDecl])
      attrs += Array(data[:annotation])

      input[:tripleConstraint] = Algebra::TripleConstraint.new(*attrs) unless attrs.empty?
    end

    # [44]    cardinality            ::= '*' | '+' | '?' | REPEAT_RANGE
    # [45]    senseFlags             ::= '^'
    # [46]    valueSet              ::= '[' valueSetValue* ']'

    # [47]    valueSetValue         ::= iriRange | literal
    production(:valueSetValue) do |input, data, callback|
      (input[:valueSetValue] ||= []) << Algebra::Value.new(data[:iriRange] || data[:literal])
    end

    # [48]    iriRange              ::= iri ('~' exclusion*)? | '.' exclusion+
    production(:iriRange) do |input, data, callback|
      exclusions = data[:exclusion].unshift(:exclusions) if data[:exclusion]
      input[:iriRange] = if data[:pattern] && exclusions
        Algebra::StemRange.new(data[:iri], exclusions)
      elsif data[:pattern]
        Algebra::StemRange.new(data[:iri])
      elsif data[:dot]
        Algebra::StemRange.new(:wildcard, exclusions)
      else
        data[:iri]
      end
    end

    # [49]    exclusion             ::= '-' iri '~'?
    production(:exclusion) do |input, data, callback|
      (input[:exclusion] ||= []) << (data[:pattern] ? Algebra::Stem.new([data[:iri]]) : data[:iri])
    end

    # [50]     include               ::= '&' shapeLabel
    production(:include) do |input, data, callback|
      input[:include] = Algebra::Inclusion.new(*data[:shapeLabel])
    end

    # [51]    annotation            ::= '//' predicate (iri | literal)
    production(:annotation) do |input, data, callback|
      annotation = Algebra::Annotation.new(data[:predicate].first, (data[:iri] || data[:literal]))
      (input[:annotation] ||= []) << annotation
    end

    # [52]    semanticActions       ::= codeDecl*

    # [53]    codeDecl              ::= '%' iri (CODE | "%")
    production(:codeDecl) do |input, data, callback|
      (input[:codeDecl] ||= []) <<  Algebra::SemAct.new([data[:iri], data[:code]].compact)
    end

    # [13t]   literal               ::= rdfLiteral | numericLiteral | booleanLiteral

    # [54]    predicate             ::= iri | RDF_TYPE
    production(:predicate) do |input, data, callback|
      (input[:predicate] ||= []) << data[:iri]
    end

    # [55]    datatype              ::= iri
    production(:datatype) do |input, data, callback|
      input[:datatype] = data[:iri]
    end

    # [56]    shapeLabel            ::= iri | blankNode
    production(:shapeLabel) do |input, data, callback|
      (input[:shapeLabel] ||= []) << (data[:iri] || data[:blankNode])
    end

    # [16t]   numericLiteral        ::= INTEGER | DECIMAL | DOUBLE
    # [129s]  rdfLiteral            ::= string (LANGTAG | '^^' datatype)?
    production(:rdfLiteral) do |input, data, callback|
      input[:literal] = literal(data[:string], data)
    end

    # [134s]  booleanLiteral        ::= 'true' | 'false'
    # [135s]  string                ::= STRING_LITERAL1 | STRING_LITERAL_LONG1
    #                                 | STRING_LITERAL2 | STRING_LITERAL_LONG2
    # [136s]  iri                   ::= IRIREF | prefixedName
    # [137s]  prefixedName          ::= PNAME_LN | PNAME_NS
    # [138s]  blankNode             ::= BLANK_NODE_LABEL

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
      when prod_data[:schema]
        prod_data[:schema]
      else
        key = prod_data.keys.first
        [key] + Array(prod_data[key])  # Creates [:key, [:triple], ...]
      end

      # Validate resulting expression
      @result.validate! if @result && validate?
      @result
    rescue EBNF::LL1::Parser::Error, EBNF::LL1::Lexer::Error =>  e
      raise ShEx::ParseError.new(e.message, lineno: e.lineno, token: e.token)
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
      unless id
        id = @options[:anon_base]
        @options[:anon_base] = @options[:anon_base].succ
      end
      @bnode_cache ||= {}
      raise Error, "Illegal attempt to reuse a BNode" if @bnode_cache[id] && @bnode_cache[id].frozen?
      @bnode_cache[id] ||= RDF::Node.new(id)
    end

    # Create URIs
    def iri(value)
      # If we have a base URI, use that when constructing a new URI
      value = RDF::URI(value)
      if base_uri && value.relative?
        base_uri.join(value)
      else
        value
      end
    end

    def ns(prefix, suffix)
      base = prefix(prefix).to_s
      suffix = suffix.to_s.sub(/^\#/, "") if base.index("#")
      debug {"ns(#{prefix.inspect}): base: '#{base}', suffix: '#{suffix}'"}
      iri(base + suffix.to_s)
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
  end # class Parser
end # module ShEx
