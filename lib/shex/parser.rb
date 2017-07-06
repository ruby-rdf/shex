# -*- encoding: utf-8 -*-
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
    include RDF::Util::Logger

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
      error(nil, "Compact IRI missing prefix definition: #{token.value}", production: :PNAME_LN) unless prefix(prefix)
    end
    terminal(:PNAME_NS,             PNAME_NS) do |prod, token, input|
      prefix = token.value[0..-2]

      input[:iri] = ns(prefix, nil)
      input[:prefix] = prefix && prefix.to_sym
    end
    terminal(:ATPNAME_LN,             ATPNAME_LN, unescape: true) do |prod, token, input|
      prefix, suffix = token.value.split(":", 2)
      prefix.sub!(/^@#{WS}*/, '')
      input[:shapeLabel] = ns(prefix, suffix)
      error(nil, "Compact IRI missing prefix definition: #{token.value}", production: :ATPNAME_LN) unless input[:shapeLabel].absolute?
    end
    terminal(:ATPNAME_NS,             ATPNAME_NS) do |prod, token, input|
      prefix = token.value[0..-2]
      prefix.sub!(/^@\s*/, '')

      input[:shapeLabel] = ns(prefix, nil)
    end
    terminal(:LANGTAG,              LANGTAG) do |prod, token, input|
      input[:language] = token.value[1..-1]
    end
    terminal(:LANG_STRING_LITERAL_LONG1, LANG_STRING_LITERAL_LONG1, unescape: true) do |prod, token, input|
      input[:string], _, input[:language] = token.value[3..-1].rpartition("'''@")
    end
    terminal(:LANG_STRING_LITERAL_LONG2, LANG_STRING_LITERAL_LONG2, unescape: true) do |prod, token, input|
      input[:string], _, input[:language] = token.value[3..-1].rpartition('"""@')
    end
    terminal(:LANG_STRING_LITERAL1,      LANG_STRING_LITERAL1, unescape: true) do |prod, token, input|
      input[:string], _, input[:language] = token.value[1..-1].rpartition("'@")
    end
    terminal(:LANG_STRING_LITERAL2,      LANG_STRING_LITERAL2, unescape: true) do |prod, token, input|
      input[:string], _, input[:language] = token.value[1..-1].rpartition('"@')
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
    terminal(:REGEXP,               REGEXP) do |prod, token, input|
      input[:regexp] = token.value
    end
    terminal(:RDF_TYPE,             RDF_TYPE) do |prod, token, input|
      input[:iri] = (a = RDF.type.dup; a.lexical = 'a'; a)
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
      when 'START'         then input[:start] = token.value.downcase.to_sym
      else
        #raise "Unexpected MC terminal: #{token.inspect}"
      end
    end

    # Productions
    # [1]     shexDoc               ::= directive* ((notStartAction | startActions) statement*)?
    production(:shexDoc) do |input, data, callback|
      data[:start] = data[:start] if data[:start]

      expressions = []
      expressions << [:base, data[:baseDecl]] if data[:baseDecl]
      expressions << [:prefix, data[:prefixDecl]] if data[:prefixDecl]
      expressions += Array(data[:codeDecl])
      expressions << Algebra::Start.new(data[:start]) if data[:start]
      expressions << data[:shapes].unshift(:shapes) if data[:shapes]

      input[:schema] = Algebra::Schema.new(*expressions, options)
      self
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
      input[:start] = Array(data[:shapeExpression]).first || data[:shape]
    end
    # [7]     startActions          ::= codeDecl+

    # [8]     statement             ::= directive | notStartAction

    # [9]     shapeExprDecl         ::= shapeLabel (shapeExpression|"EXTERNAL")
    production(:shapeExprDecl) do |input, data, callback|
      id = Array(data[:shapeLabel]).first
      expression = case Array(data[:shapeExpression]).first
      when Algebra::NodeConstraint, Algebra::Or, Algebra::And, Algebra::Not, Algebra::Shape, RDF::Resource
        Array(data[:shapeExpression]).first
      else
        data[:external] ? Algebra::External.new() : Algebra::Shape.new()
      end
      expression.id = id if id && !expression.is_a?(RDF::Resource)

      (input[:shapes] ||= []) << expression
    end

    # [10]    shapeExpression  ::= shapeAtomNoRef shapeOr?
    #                            | "NOT" (shapeAtomNoRef | shapeRef) shapeOr?
    #                            | shapeRef shapeOr
    production(:shapeExpression) do |input, data, callback|
      expression = Array(data[:shapeExpression]).first || data[:shape]
      expression = Algebra::Not.new(expression) if data[:not]
      (input[:shapeExpression] ||= []) << expression
    end

    # [11]    inlineShapeExpression ::= inlineShapeOr
    # [12]    shapeOr               ::= shapeOrA | shapeOrB shapeOrA?
    # [12a]   shapeOrA              ::= ("OR" shapeAnd)+
    start_production(:shapeOrA) do |input, data, callback|
      data[:shapeExpression] = input.delete(:shapeExpression)
      data[:shapeExpression] ||=  Array(input.delete(:shape)) if input[:shape]
      data[:shapeExpression] = [Algebra::Not.new(*data[:shapeExpression])] if input.delete(:not)
    end
    production(:shapeOrA) do |input, data, callback|
      shape_or(input, data)
    end
    # [12b]   shapeOrB              ::= ("AND" shapeNot)+
    start_production(:shapeOrB) do |input, data, callback|
      data[:shapeExpression] = input.delete(:shapeExpression)
      data[:shapeExpression] ||=  Array(input.delete(:shape)) if input[:shape]
      data[:shapeExpression] = [Algebra::Not.new(*data[:shapeExpression])] if input.delete(:not)
    end
    production(:shapeOrB) do |input, data, callback|
      shape_and(input, data)
    end

    # [13]    inlineShapeOr         ::= inlineShapeAnd ("OR" inlineShapeAnd)*
    production(:inlineShapeOr) do |input, data, callback|
      shape_or(input, data)
    end
    def shape_or(input, data)
      input.merge!(data.dup.keep_if {|k, v| [:closed, :extraPropertySet, :codeDecl].include?(k)})
      expression = if Array(data[:shapeExpression]).length > 1
        Algebra::Or.new(*data[:shapeExpression], {})
      else
        Array(data[:shapeExpression]).first
      end
      (input[:shapeExpression] ||= []) << expression if expression
    rescue ArgumentError => e
      error(nil, "Argument Error on OR: #{e.message}")
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
        #memo.concat(expr.is_a?(Algebra::And) ? expr.operands : [expr])
        memo.concat([expr])
      end

      expression = if expressions.length > 1
        Algebra::And.new(*expressions, {})
      else
        expressions.first
      end
      (input[:shapeExpression] ||= []) << expression if expression
    rescue ArgumentError => e
      error(nil, "Argument Error on AND: #{e.message}")
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
      expression = Array(data[:shapeExpression]).first
      expression = Algebra::Not.new(expression) if data[:not]
      #error(nil, "Expected an atom for NOT") unless expression
      (input[:shapeExpression] ||= []) << expression if expression
    end
    private :shape_not

    # [18]    shapeAtom             ::= nodeConstraint shapeOrRef?
    #                                 | shapeOrRef
    #                                 | "(" shapeExpression ")"
    #                                 | '.'  # no constraint
    production(:shapeAtom) do |input, data, callback|
      shape_atom(input, data)
    end

    # [19]   shapeAtomNoRef        ::= nodeConstraint shapeOrRef?
    #                                 | shapeDefinition
    #                                 | "(" shapeExpression ")"
    #                                 | '.'  # no constraint
    production(:shapeAtomNoRef) do |input, data, callback|
      shape_atom(input, data)
    end

    # [20]    inlineShapeAtom       ::= nodeConstraint inlineShapeOrRef?
    #                                 | inlineShapeOrRef nodeConstraint?
    #                                 | "(" shapeExpression ")"
    #                                 | '.'  # no constraint
    production(:inlineShapeAtom) do |input, data, callback|
      shape_atom(input, data)
    end
    def shape_atom(input, data)
      constraint = data[:nodeConstraint]
      shape = data[:shapeOrRef] || Array(data[:shapeExpression]).first || data[:shape]
      input.merge!(data.dup.keep_if {|k, v| [:closed, :extraPropertySet, :codeDecl].include?(k)})

      expression = [constraint, shape].compact
      expression = case expression.length
      when 0 then nil
      when 1 then expression.first
      else        Algebra::And.new(*expression, {})
      end

      (input[:shapeExpression] ||= []) << expression if expression
    end
    private :shape_atom

    # [21]    shapeOrRef            ::= shapeDefinition | shapeRef
    production(:shapeOrRef) do |input, data, callback|
      shape_or_ref(input, data)
    end
    # [22]    inlineShapeOrRef      ::= inlineShapeDefinition | shapeRef
    production(:inlineShapeOrRef) do |input, data, callback|
      shape_or_ref(input, data)
    end
    def shape_or_ref(input, data)
      input.merge!(data.dup.keep_if {|k, v| [:closed, :extraPropertySet, :codeDecl].include?(k)})
      input[:shapeOrRef] = data[:shape] if data[:shape]
    rescue ArgumentError => e
      error(nil, "Argument Error on ShapeOrRef: #{e.message}")
    end
    private :shape_or_ref

    # [23]    shapeRef              ::= ATPNAME_LN | ATPNAME_NS | '@' shapeLabel
    production(:shapeRef) do |input, data, callback|
      input[:shape] = Array(data[:shapeLabel]).first
    end

    # [24]    litNodeConstraint     ::= "LITERAL" xsFacet*
    #                                 | datatype xsFacet*
    #                                 | valueSet xsFacet*
    #                                 | numericFacet+
    production(:litNodeConstraint) do |input, data, callback|
      # Semantic validate (A Syntax error)
      case
      when data[:datatype] && data[:numericFacet]
        # Can only use a numeric facet on a numeric datatype
        l = RDF::Literal.new("1", datatype: data[:datatype])
        error(nil, "Numeric facet used on non-numeric datatype: #{data[:datatype]}", production: :nodeConstraint) unless l.is_a?(RDF::Literal::Numeric)
      end

      attrs = []
      attrs << [:datatype, data[:datatype]] if data [:datatype]
      attrs += Array(data[:shapeAtomLiteral])
      attrs += Array(data[:valueSetValue])
      attrs += Array(data[:numericFacet])
      attrs += Array(data[:stringFacet])

      input[:nodeConstraint] = Algebra::NodeConstraint.new(*attrs.compact, {})
    end

    # [25]    nonLitNodeConstraint  ::= nonLiteralKind stringFacet*
    #                                 | stringFacet+
    production(:nonLitNodeConstraint) do |input, data, callback|
      # Semantic validate (A Syntax error)

      attrs = []
      attrs += Array(data[:nonLiteralKind])
      attrs += Array(data[:stringFacet])

      input[:nodeConstraint] = Algebra::NodeConstraint.new(*attrs.compact, {})
    end

    # [26]    nonLiteralKind        ::= "IRI" | "BNODE" | "NONLITERAL"

    # [27]    xsFacet               ::= stringFacet | numericFacet
    # [28]    stringFacet           ::= stringLength INTEGER
    #                                 | REGEXP
    production(:stringFacet) do |input, data, callback|
      input[:stringFacet] ||= []
      input[:stringFacet] << if data[:stringLength]
        if input[:stringFacet].flatten.include?(data[:stringLength])
          error(nil, "#{data[:stringLength]} constraint may only be used once in a Node Constraint", production: :stringFacet)
        end
        [data[:stringLength], data[:literal]]
      elsif re = data[:regexp]
        unless re =~ %r(^/(.*)/([smix]*)$)
          error(nil, "#{re.inspect} regular expression must be in the form /pattern/flags?", production: :stringFacet)
        end
        flags = $2 unless $2.to_s.empty?
        pattern = $1.gsub('\\/', '/').gsub(UCHAR) do
          [($1 || $2).hex].pack('U*')
        end.force_encoding(Encoding::UTF_8)

        # Any other escaped character is a syntax error
        if pattern.match(%r([^\\]\\[^nrt/\\|\.?*+\[\]\(\){}$#x2D#x5B#x5D#x5E-]))
          error(nil, "Regexp contains illegal escape: #{pattern.inspect}", production: :stringFacet)
        end

        [:pattern, pattern, flags].compact
      end
    end

    # [29]    stringLength          ::= "LENGTH" | "MINLENGTH" | "MAXLENGTH"

    # [30]    numericFacet          ::= numericRange (numericLiteral | string '^^' datatype )
    #                                 | numericLength INTEGER
    production(:numericFacet) do |input, data, callback|
      input[:numericFacet] ||= []
      input[:numericFacet] << if data[:numericRange]
        literal = data[:literal] || literal(data[:string], datatype: data[:datatype])
        error(nil, "numericRange must use a numeric datatype: #{data[:datatype]}", production: :numericFacet) unless literal.is_a?(RDF::Literal::Numeric)
        [data[:numericRange], literal]
      elsif data[:numericLength]
        [data[:numericLength], data[:literal]]
      end
    end

    # [31]    numericRange          ::= "MININCLUSIVE" | "MINEXCLUSIVE" | "MAXINCLUSIVE" | "MAXEXCLUSIVE"
    # [32]    numericLength         ::= "TOTALDIGITS" | "FRACTIONDIGITS"

    # [33]    shapeDefinition       ::= (includeSet | extraPropertySet | "CLOSED")* '{' tripleExpression? '}' annotation* semanticActions
    production(:shapeDefinition) do |input, data, callback|
      shape_definition(input, data)
    end
    # [34]    inlineShapeDefinition ::= (includeSet | extraPropertySet | "CLOSED")* '{' tripleExpression? '}'
    production(:inlineShapeDefinition) do |input, data, callback|
      shape_definition(input, data)
    end
    def shape_definition(input, data)
      # FIXME: includeSet
      expression = data[:tripleExpression]
      attrs = Array(data[:extraPropertySet])
      attrs << :closed if data[:closed]
      attrs << expression if expression
      attrs += Array(data[:annotation])
      attrs += Array(data[:codeDecl])

      input[:shape] = Algebra::Shape.new(*attrs, {})
    end
    private :shape_definition

    # [35]     extraPropertySet       ::= "EXTRA" predicate+
    production(:extraPropertySet) do |input, data, callback|
      (input[:extraPropertySet] ||= []) << data[:predicate].unshift(:extra)
    end

    # [36]    tripleExpression      ::= oneOfTripleExpr
    # [37]    oneOfTripleExpr           ::= groupTripleExpr ('|' groupTripleExpr)*
    production(:oneOfTripleExpr) do |input, data, callback|
      expression = if Array(data[:tripleExpression]).length > 1
        Algebra::OneOf.new(*data[:tripleExpression], {})
      else
        Array(data[:tripleExpression]).first
      end
      input[:tripleExpression] = expression if expression
    end

    # [40]    groupTripleExpr            ::= unaryTripleExpr (';' unaryTripleExpr?)*
    production(:groupTripleExpr) do |input, data, callback|
      expression = if Array(data[:tripleExpression]).length > 1
        Algebra::EachOf.new(*data[:tripleExpression], {})
      else
        Array(data[:tripleExpression]).first
      end
      (input[:tripleExpression] ||= []) << expression if expression
    end

    # [43]    unaryTripleExpr            ::= productionLabel? (tripleConstraint | bracketedTripleExpr) | include
    production(:unaryTripleExpr) do |input, data, callback|
      expression = data[:tripleExpression]
      expression.id = data[:productionLabel] if expression && data[:productionLabel]

      (input[:tripleExpression] ||= []) << expression if expression
    end

    # [43a]    productionLabel       ::= '$' (iri | blankNode)
    production(:productionLabel) do |input, data, callback|
      input[:productionLabel] = data[:iri] || data[:blankNode]
    end

    # [44]    bracketedTripleExpr   ::= '(' oneOfTripleExpr ')' cardinality? annotation* semanticActions
    production(:bracketedTripleExpr) do |input, data, callback|
      # XXX cardinality? annotation* semanticActions
      case expression = data[:tripleExpression]
      when Algebra::OneOf, Algebra::EachOf
      else
        error(nil, "Bracketed Expression requires multiple contained expressions", production: :bracketedTripleExpr)
      end
      cardinality = data.fetch(:cardinality, {})
      attrs = [
        ([:min, cardinality[:min]] if cardinality[:min]),
        ([:max, cardinality[:max]] if cardinality[:max])
      ].compact
      attrs += Array(data[:codeDecl])
      attrs += Array(data[:annotation])

      expression.operands.concat(attrs)
      input[:tripleExpression] = expression
    end

    # [45]    tripleConstraint      ::= senseFlags? predicate shapeExpression cardinality? annotation* semanticActions
    production(:tripleConstraint) do |input, data, callback|
      cardinality = data.fetch(:cardinality, {})
      attrs = [
        (:inverse if data[:inverse] || data[:not]),
        [:predicate, Array(data[:predicate]).first],
        Array(data[:shapeExpression]).first,
        ([:min, cardinality[:min]] if cardinality[:min]),
        ([:max, cardinality[:max]] if cardinality[:max])
      ].compact
      attrs += Array(data[:codeDecl])
      attrs += Array(data[:annotation])

      input[:tripleExpression] = Algebra::TripleConstraint.new(*attrs, {}) unless attrs.empty?
    end

    # [46]    cardinality            ::= '*' | '+' | '?' | REPEAT_RANGE
    # [47]    senseFlags             ::= '^'
    # [48]    valueSet              ::= '[' valueSetValue* ']'

    # [49]    valueSetValue         ::= iriRange | literalRange | languageRange | '.' exclusion+
    production(:valueSetValue) do |input, data, callback|
      range = data[:iriRange] || data[:literalRange] || data[:languageRange]
      if !range
        # All exclusions must be consistent IRI/Literal/Language
        case data[:exclusion].first
        when Algebra::IriStem, RDF::URI
          unless data[:exclusion].all? {|e| e.is_a?(Algebra::IriStem) || e.is_a?(RDF::URI)}
            error(nil, "Exclusions must all be IRI type")
          end
          range = Algebra::IriStemRange.new(:wildcard, data[:exclusion].unshift(:exclusions))
        when Algebra::LiteralStem, RDF::Literal
          unless data[:exclusion].all? {|e| e.is_a?(Algebra::LiteralStem) || e.is_a?(RDF::Literal)}
            error(nil, "Exclusions must all be Literal type")
          end
          range = Algebra::LiteralStemRange.new(:wildcard, data[:exclusion].unshift(:exclusions))
        else
          unless data[:exclusion].all? {|e| e.is_a?(Algebra::LanguageStem) || e.is_a?(String)}
            error(nil, "Exclusions must all be Language type")
          end
          range = Algebra::LanguageStemRange.new(:wildcard, data[:exclusion].unshift(:exclusions))
        end
      end
      (input[:valueSetValue] ||= []) << Algebra::Value.new(range)
    end

    # [50]    exclusion             ::= '-' (iri | literal | LANGTAG) '~'?
    production(:exclusion) do |input, data, callback|
      (input[:exclusion] ||= []) << if data[:pattern]
        case
        when data[:iri] then Algebra::IriStem.new(data[:iri])
        when data[:literal] then Algebra::LiteralStem.new(data[:literal])
        when data[:language] then Algebra::LanguageStem.new(data[:language])
        end
      else
        data[:iri] || data[:literal] || data[:language]
      end
    end

    # [51]    iriRange              ::= iri ('~' iriExclusion*)?
    production(:iriRange) do |input, data, callback|
      exclusions = data[:exclusion].unshift(:exclusions) if data[:exclusion]
      input[:iriRange] = if data[:pattern] && exclusions
        Algebra::IriStemRange.new(data[:iri], exclusions)
      elsif data[:pattern]
        Algebra::IriStem.new(data[:iri])
      elsif data[:dot]
        Algebra::IriStemRange.new(:wildcard, exclusions)
      else
        data[:iri]
      end
    end

    # [52]    iriExclusion             ::= '-' iri '~'?
    production(:iriExclusion) do |input, data, callback|
      val = data[:iri]
      (input[:exclusion] ||= []) << (data[:pattern] ? Algebra::IriStem.new(val) : val)
    end

    # [53]    literalRange              ::= literal ('~' literalExclusion*)?
    production(:literalRange) do |input, data, callback|
      exclusions = data[:exclusion].unshift(:exclusions) if data[:exclusion]
      input[:literalRange] = if data[:pattern] && exclusions
        Algebra::LiteralStemRange.new(data[:literal], exclusions)
      elsif data[:pattern]
        Algebra::LiteralStem.new(data[:literal])
      elsif data[:dot]
        Algebra::LiteralStemRange.new(:wildcard, exclusions)
      else
        data[:literal]
      end
    end

    # [54]    literalExclusion             ::= '-' literal '~'?
    production(:literalExclusion) do |input, data, callback|
      val = data[:literal]
      (input[:exclusion] ||= []) << (data[:pattern] ? Algebra::LiteralStem.new(val) : val)
    end

    # [55]    languageRange              ::= LANGTAG ('~' languageExclusion*)?
    production(:languageRange) do |input, data, callback|
      exclusions = data[:exclusion].unshift(:exclusions) if data[:exclusion]
      input[:languageRange] = if data[:pattern] && exclusions
        Algebra::LanguageStemRange.new(data[:language], exclusions)
      elsif data[:pattern]
        Algebra::LanguageStem.new(data[:language])
      elsif data[:dot]
        Algebra::LanguageStemRange.new(:wildcard, exclusions)
      else
        Algebra::Language.new(data[:language])
      end
    end

    # [56]    languageExclusion             ::= '-' literal '~'?
    production(:languageExclusion) do |input, data, callback|
      val = data[:language]
      (input[:exclusion] ||= []) << (data[:pattern] ? Algebra::LanguageStem.new(val) : val)
    end

    # [57]     include               ::= '&' shapeLabel
    production(:include) do |input, data, callback|
      input[:tripleExpression] = data[:shapeLabel].first
    end

    # [58]    annotation            ::= '//' predicate (iri | literal)
    production(:annotation) do |input, data, callback|
      annotation = Algebra::Annotation.new([:predicate, data[:predicate].first], (data[:iri] || data[:literal]))
      (input[:annotation] ||= []) << annotation
    end

    # [59]    semanticActions       ::= codeDecl*

    # [60]    codeDecl              ::= '%' iri (CODE | "%")
    production(:codeDecl) do |input, data, callback|
      (input[:codeDecl] ||= []) <<  Algebra::SemAct.new(*[data[:iri], data[:code]].compact, {})
    end

    # [13t]   literal               ::= rdfLiteral | numericLiteral | booleanLiteral

    # [61]    predicate             ::= iri | RDF_TYPE
    production(:predicate) do |input, data, callback|
      (input[:predicate] ||= []) << data[:iri]
    end

    # [62]    datatype              ::= iri
    production(:datatype) do |input, data, callback|
      input[:datatype] = data[:iri]
    end

    # [63]    shapeLabel            ::= iri | blankNode
    production(:shapeLabel) do |input, data, callback|
      (input[:shapeLabel] ||= []) << (data[:iri] || data[:blankNode])
    end

    # [16t]   numericLiteral        ::= INTEGER | DECIMAL | DOUBLE
    # [129s]  rdfLiteral            ::= langString | string ('^^' datatype)?
    production(:rdfLiteral) do |input, data, callback|
      input[:literal] = literal(data[:string], data)
    end

    # [134s]  booleanLiteral        ::= 'true' | 'false'
    # [135s]  string                ::= STRING_LITERAL1 | STRING_LITERAL_LONG1
    #                                 | STRING_LITERAL2 | STRING_LITERAL_LONG2
    # [66]   langString            ::= LANG_STRING_LITERAL1 | LANG_STRING_LITERAL_LONG1
    #                                | LANG_STRING_LITERAL2 | LANG_STRING_LITERAL_LONG2
    # [136s]  iri                   ::= IRIREF | prefixedName
    # [1372]  prefixedName          ::= PNAME_LN | PNAME_NS
    # [138s]  blankNode             ::= BLANK_NODE_LABEL

    ##
    # Initializes a new parser instance.
    #
    # @example parsing a ShExC schema
    #   schema = ShEx::Parser.new(%(
    #     PREFIX ex: <http://schema.example/> ex:IssueShape {ex:state IRI}
    #   ).parse
    #
    # @param  [String, IO, StringIO, #to_s]          input
    # @param  [Hash{Symbol => Object}] options
    # @option options [Hash]     :prefixes     (Hash.new)
    #   the prefix mappings to use (for acessing intermediate parser productions)
    # @option options [#to_s]    :base_uri     (nil)
    #   the base URI to use when resolving relative URIs (for acessing intermediate parser productions)
    # @option options [#to_s]    :anon_base     ("b0")
    #   Basis for generating anonymous Nodes
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
    # @raise [ShEx::NotSatisfied] if not satisfied
    # @raise [ShEx::ParseError] when a syntax error is detected
    # @raise [ShEx::StructureError, ArgumentError] on structural problems with schema
    def initialize(input = nil, options = {}, &block)
      @input = case input
      when IO, StringIO then input.read
      else input.to_s.dup
      end
      @input.encode!(Encoding::UTF_8) if @input.respond_to?(:encode!)
      @options = {anon_base: "b0", validate: false}.merge(options)

      debug("base IRI") {base_uri.inspect}
      debug("validate") {validate?.inspect}

      if block_given?
        case block.arity
          when 0 then instance_eval(&block)
          else block.call(self)
        end
      end
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
    # @return [ShEx::Algebra::Schema] The executable parsed expression.
    # @raise [ShEx::ParseError] when a syntax error is detected
    # @raise [ShEx::StructureError, ArgumentError] on structural problems with schema
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
          if options[:logger]
            level, lineno, depth, *args = data
            case level
            when 0
              log_error(*args, depth: depth, lineno: lineno)
            when 1
              log_warn(*args, depth: depth, lineno: lineno)
            when 2
              log_info(*args, depth: depth, lineno: lineno)
            else
              log_debug(*args, depth: depth, lineno: lineno)
            end
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
      raise ShEx::ParseError, e.message, e.backtrace
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
      @options[:base_uri]
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
    # Returns `true` when resolving IRIs, otherwise BASE and PREFIX are retained in the output algebra.
    #
    # @return [Boolean] `true` or `false`
    # @since  1.0.3
    def validate?
      @options[:validate]
    end

    # Generate a BNode identifier
    def bnode(id)
      RDF::Node.intern(id)
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
