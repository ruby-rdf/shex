require 'sparql/algebra'

module ShEx::Algebra

  ##
  # The ShEx operator.
  #
  # @abstract
  class Operator
    extend SPARQL::Algebra::Expression
    include RDF::Util::Logger

    # Location of schema including this operator
    attr_accessor :schema

    # Initialization options
    attr_accessor :options

    ARITY = -1 # variable arity

    ##
    # Initializes a new operator instance.
    #
    # @overload initialize(*operands)
    #   @param  [Array<RDF::Term>] operands
    #
    # @overload initialize(*operands, options)
    #   @param  [Array<RDF::Term>] operands
    #   @param  [Hash{Symbol => Object}] options
    #     any additional options
    #   @option options [Boolean] :memoize (false)
    #     whether to memoize results for particular operands
    # @raise  [TypeError] if any operand is invalid
    def initialize(*operands)
      @options  = operands.last.is_a?(Hash) ? operands.pop.dup : {}
      @operands = operands.map! do |operand|
        case operand
          when Array
            operand.each do |op|
              op.parent = self if op.respond_to?(:parent=)
            end
            operand
          when Operator, RDF::Term, RDF::Query, RDF::Query::Pattern, Array, Symbol
            operand.parent = self if operand.respond_to?(:parent=)
            operand
          when TrueClass, FalseClass, Numeric, String, DateTime, Date, Time
            RDF::Literal(operand)
          when NilClass
            raise ArgumentError, "Found nil operand for #{self.class.name}"
          else raise TypeError, "invalid ShEx::Algebra::Operator operand: #{operand.inspect}"
        end
      end

      if options[:logger]
        options[:depth] = 0
        each_descendant(1) do |depth, operand|
          if operand.respond_to?(:options)
            operand.options[:logger] = options[:logger]
            operand.options[:depth] = depth
          end
        end
      end
    end

    ##
    # Is this shape closed?
    # @return [Boolean]
    def closed?
      operands.include?(:closed)
    end

    ##
    # Semantic Actions
    # @return [Array<SemAct>]
    def semantic_actions
      operands.select {|o| o.is_a?(SemAct)}
    end

    # Does this operator include Satisfiable?
    def satisfiable?; false; end

    # Does this operator include TripleExpression?
    def triple_expression?; false; end

    # Does this operator a SemAct?
    def semact?; false; end

    ##
    # On a result instance, the statements that matched this expression.
    # @return [Array<Statement>]
    def matched
      Array((operands.detect {|op| op.is_a?(Array) && op[0] == :matched} || [:matched])[1..-1])
    end
    def matched=(statements)
      operands.delete_if {|op| op.is_a?(Array) && op[0] == :matched}
      operands << statements.unshift(:matched) unless (statements || []).empty?
    end

    ##
    # On a result instance, the statements that did not match this expression (failure only).
    # @return [Array<Statement>]
    def unmatched
      Array((operands.detect {|op| op.is_a?(Array) && op[0] == :unmatched} || [:unmatched])[1..-1])
    end
    def unmatched=(statements)
      operands.delete_if {|op| op.is_a?(Array) && op[0] == :unmatched}
      operands << statements.unshift(:unmatched) unless (statements || []).empty?
    end

    ##
    # On a result instance, the sub-expressions which were matched.
    # @return [Array<Operator>]
    def satisfied
      Array((operands.detect {|op| op.is_a?(Array) && op[0] == :satisfied} || [:satisfied])[1..-1])
    end
    def satisfied=(ops)
      operands.delete_if {|op| op.is_a?(Array) && op[0] == :satisfied}
      operands << ops.unshift(:satisfied) unless (ops || []).empty?
    end

    ##
    # On a result instance, the sub-satisfieables which were not satisfied. (failure only).
    # @return [Array<Operator>]
    def unsatisfied
      Array((operands.detect {|op| op.is_a?(Array) && op[0] == :unsatisfied} || [:unsatisfied])[1..-1])
    end
    def unsatisfied=(ops)
      operands.delete_if {|op| op.is_a?(Array) && op[0] == :unsatisfied}
      operands << ops.unshift(:unsatisfied) unless (ops || []).empty?
    end

    ##
    # Duplication this operand, and add `matched`, `unmatched`, `satisfied`, and `unsatisfied` operands for accessing downstream.
    #
    # @return [Operand]
    def satisfy(matched: nil, unmatched: nil, satisfied: nil, unsatisfied: nil)
      log_debug(self.class.const_get(:NAME), "satisfied", depth: options.fetch(:depth, 0))
      expression = self.dup
      expression.matched = Array(matched) if matched
      expression.unmatched = Array(unmatched) if unmatched
      expression.satisfied = Array(satisfied) if satisfied
      expression.unsatisfied = Array(unsatisfied) if unsatisfied
      expression
    end

    ##
    # Exception handling
    def not_matched(message, matched: nil, unmatched: nil, satisfied: nil, unsatisfied: nil, **opts, &block)
      expression = opts.fetch(:expression, self).satisfy(
        matched:     matched,
        unmatched:   unmatched,
        satisfied:   satisfied,
        unsatisfied: unsatisfied)
      exception = opts.fetch(:exception, ShEx::NotMatched)
      status(message) {(block_given? ? block.call : "") + "expression: #{expression.to_sxp}"}
      raise exception.new(message, expression: expression)
    end

    def not_satisfied(message, matched: nil, unmatched: nil, satisfied: nil, unsatisfied: nil, **opts)
      expression = opts.fetch(:expression, self).satisfy(
        matched:     matched,
        unmatched:   unmatched,
        satisfied:   satisfied,
        unsatisfied: unsatisfied)
      exception = opts.fetch(:exception, ShEx::NotSatisfied)
      status(message) {(block_given? ? block.call : "") + "expression: #{expression.to_sxp}"}
      raise exception.new(message, expression: expression)
    end

    def structure_error(message, **opts)
      expression = opts.fetch(:expression, self)
      exception = opts.fetch(:exception, ShEx::StructureError)
      log_error(message, depth: options.fetch(:depth, 0), exception: exception) {"expression: #{expression.to_sxp}"}
    end

    def status(message, &block)
      log_debug(self.class.const_get(:NAME), message, depth: options.fetch(:depth, 0), &block)
      true
    end

    ##
    # The operands to this operator.
    #
    # @return [Array]
    attr_reader :operands

    ##
    # Returns the operand at the given `index`.
    #
    # @param  [Integer] index
    #   an operand index in the range `(0...(operands.count))`
    # @return [RDF::Term]
    def operand(index = 0)
      operands[index]
    end

    ##
    # Returns the binary S-Expression (SXP) representation of this operator.
    #
    # @return [Array]
    # @see    https://en.wikipedia.org/wiki/S-expression
    def to_sxp_bin
      operator = [self.class.const_get(:NAME)].flatten.first
      [operator, *(operands || []).map(&:to_sxp_bin)]
    end

    ##
    # Returns an S-Expression (SXP) representation of this operator
    #
    # @return [String]
    def to_sxp
      begin
        require 'sxp' # @see http://rubygems.org/gems/sxp
      rescue LoadError
        abort "SPARQL::Algebra::Operator#to_sxp requires the SXP gem (hint: `gem install sxp')."
      end
      require 'sparql/algebra/sxp_extensions'

      to_sxp_bin.to_sxp
    end

    ##
    # Creates an operator instance from a parsed ShExJ representation
    # @param [Hash] operator
    # @param [Hash] options ({})
    # @option options [RDF::URI] :base
    # @option options [Hash{String => RDF::URI}] :prefixes
    # @return [Operator]
    def self.from_shexj(operator, options = {})
      operands = []

      operator.each do |k, v|
        case k
        when /length|pattern|clusive/          then operands << [k.to_sym, v]
        when 'min', 'max', 'inverse', 'closed' then operands << [k.to_sym, v]
        when 'nodeKind'                        then operands << v.to_sym
        when 'object'                          then operands << value(v, options)
        when 'start'                           then operands << Start.new(ShEx::Algebra.from_shexj(v, options))
        when 'base'
          options[:base_uri] = RDF::URI(v)
          operands << [:base, options[:base_uri]]
        when 'prefixes'
          options[:prefixes] = v.inject({}) do |memo, (kk,vv)|
            memo.merge(kk => RDF::URI(vv))
          end
          operands << [:prefix, options[:prefixes]]
        when 'shapes'
          operands << [:shapes,
                       v.inject({}) do |memo, (kk,vv)|
                         memo.merge(iri(kk, options) => ShEx::Algebra.from_shexj(vv, options))
                       end]
        when 'reference', 'include', 'stem', 'name'
          # Value may be :wildcard for stem
          operands << (v.is_a?(Symbol) ? v : iri(v, options))
        when 'predicate' then operands << iri(v, options)
        when 'extra', 'datatype'
          v = [v] unless v.is_a?(Array)
          operands << (v.map {|op| iri(op, options)}).unshift(k.to_sym)
        when 'exclusions'
          v = [v] unless v.is_a?(Array)
          operands << v.map do |op|
            op.is_a?(Hash) ?
              ShEx::Algebra.from_shexj(op, options) :
              value(op, options)
          end.unshift(:exclusions)
        when 'min', 'max', 'inverse', 'closed', 'valueExpr', 'semActs',
             'shapeExpr', 'shapeExprs', 'startActs', 'expression',
             'expressions', 'annotations'
          v = [v] unless v.is_a?(Array)
          operands += v.map {|op| ShEx::Algebra.from_shexj(op, options)}
        when 'code'
          operands << v
        when 'values'
          v = [v] unless v.is_a?(Array)
          operands += v.map do |op|
            Value.new(op.is_a?(Hash) ?
                        ShEx::Algebra.from_shexj(op, options) :
                        value(op, options))
          end
        end
      end

      new(*operands)
    end

    def json_type
      self.class.name.split('::').last
    end

    def to_json(options = nil)
      obj = {'type' => json_type}
      operands.each do |op|
        case op
        when Array
          # First element should be a symbol
          case sym = op.first
          when :base            then obj['base'] = op.last.to_s
          when :datatype,
               :pattern         then obj[op.first.to_s] = op.last.to_s
          when :extra           then obj['extra'] = Array(op[1..-1]).map(&:to_s)
          when :prefix          then obj['prefixes'] = op.last.inject({}) {|memo, (k,v)| memo.merge(k.to_s => v.to_s)}
          when :shapes          then obj['shapes'] = op.last.inject({}) {|memo, (k,v)| memo.merge(k.to_s => v.to_json)}
          when :minlength,
               :maxlength,
               :length,
               :mininclusive,
               :maxinclusive,
               :minexclusive,
               :maxexclusive,
               :totaldigits,
               :fractiondigits  then obj[op.first.to_s] = op.last.object
          when :min, :max       then obj[op.first.to_s] = op.last
          when Symbol           then obj[sym.to_s] = Array(op[1..-1]).map(&:to_json)
          else
            raise "Expected array to start with a symbol for #{self}"
          end
        when :wildcard  then #skip
        when Annotation then (obj['annotations'] ||= []) << op.to_json
        when SemAct     then (obj[is_a?(Schema) ? 'startActs' : 'semActs'] ||= []) << op.to_json
        when Start      then obj['start'] = op.to_json
        when RDF::Value
          case self
          when TripleConstraint then obj['predicate'] = op.to_s
          when Stem, StemRange  then obj['stem'] = op.to_s
          when Inclusion        then obj['include'] = op.to_s
          when ShapeRef         then obj['reference'] = op.to_s
          when SemAct           then obj[op.is_a?(RDF::URI) ? 'name' : 'code'] = op.to_s
          else
            raise "How to serialize Value #{op.inspect} to json for #{self}"
          end
        when Symbol
          case self
          when NodeConstraint   then obj['nodeKind'] = op.to_s
          when Shape            then obj['closed'] = true
          when TripleConstraint then obj['inverse'] = true
          else
            raise "How to serialize Symbol #{op.inspect} to json for #{self}"
          end
        when TripleConstraint, EachOf, OneOf, Inclusion
          case self
          when EachOf, OneOf
            (obj['expressions'] ||= []) << op.to_json
          else
            obj['expression'] = op.to_json
          end
        when NodeConstraint
          case self
          when And, Or
            (obj['shapeExprs'] ||= []) << op.to_json
          else
            obj['valueExpr'] = op.to_json
          end
        when And, Or, Shape, Not, ShapeRef
          case self
          when And, Or
            (obj['shapeExprs'] ||= []) << op.to_json
          when TripleConstraint
            obj['valueExpr'] = op.to_json
          else
            obj['shapeExpr'] = op.to_json
          end
        when Value
          obj['values'] ||= []
          Array(op).map {|o| o.operands}.flatten.each do |oo|
            obj['values'] << case oo
            when RDF::Literal then RDF::NTriples.serialize(oo)
            when RDF::Resource then oo.to_s
            else oo.to_json
            end
          end
        else
          raise "How to serialize #{op.inspect} to json for #{self}"
        end
      end
      obj
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

    def iri(value, options = @options)
      self.class.iri(value, options)
    end

    # Create URIs
    # @param [RDF::Value, String] value
    # @param [Hash{Symbol => Object}] options
    # @option options [RDF::URI] :base_uri
    # @option options [Hash{String => RDF::URI}] :prefixes
    # @return [RDF::Value]
    def self.iri(value, options)
      # If we have a base URI, use that when constructing a new URI
      case value
      when RDF::URI
        base_uri = options[:base_uri]
        if base_uri && value.relative?
          base_uri.join(value)
        else
          value
        end
      when RDF::Value then value
      when /^_:/ then
        id = value[2..-1].to_s
        RDF::Node.intern(id)
      when /^(\w+):(\S+)$/
        prefixes = options.fetch(:prefixes, {})
        if prefixes.has_key?($1)
          prefixes[$1].join($2)
        elsif RDF.type == value
          a = RDF.type.dup; a.lexical = 'a'; a
        else
          RDF::URI(value)
        end
      else
        base_uri = options[:base_uri]
        if base_uri
          base_uri.join(value)
        else
          RDF::URI(value)
        end
      end
    end

    # Create Values, with "clever" matching to see if it might be a value, IRI or BNode.
    # @param [RDF::Value, String] value
    # @param [Hash{Symbol => Object}] options
    # @option options [RDF::URI] :base_uri
    # @option options [Hash{String => RDF::URI}] :prefixes
    # @return [RDF::Value]
    def self.value(value, options)
      # If we have a base URI, use that when constructing a new URI
      case value
      when /^"([^"])*"(?:^^(.*))?(@.*)?$/
        # Sorta N-Triples encoded
        value = %("#{$1}"^^<#{$2}>) if $2
        RDF::NTriples.unserialize(value)
      when RDF::Value, /^(\w+):/ then iri(value, options)
      else RDF::Literal(value)
      end
    end

    ##
    # Returns a developer-friendly representation of this operator.
    #
    # @return [String]
    def inspect
      sprintf("#<%s:%#0x(%s)>", self.class.name, __id__, operands.to_sse.gsub(/\s+/m, ' '))
    end

    ##
    # @param  [Statement] other
    # @return [Boolean]
    def eql?(other)
      other.class == self.class && other.operands == self.operands
    end
    alias_method :==, :eql?

    ##
    # Enumerate via depth-first recursive descent over operands, yielding each operator
    # @param [Integer] depth incrementeded for each depth of operator, and provided to block if Arity is 2
    # @yield operator
    # @yieldparam [Object] operator
    # @return [Enumerator]
    def each_descendant(depth = 0, &block)
      if block_given?
        operands.each do |operand|
          case operand
          when Array
            operand.each do |op|
              op.each_descendant(depth + 1, &block) if op.respond_to?(:each_descendant)
            end
          else
            operand.each_descendant(depth + 1, &block) if operand.respond_to?(:each_descendant)
          end

          case block.arity
          when 1 then block.call(operand)
          else block.call(depth, operand)
          end
        end
      end
      enum_for(:each_descendant)
    end
    alias_method :descendants, :each_descendant
    alias_method :each, :each_descendant

    ##
    # Parent expression, if any
    #
    # @return [Operator]
    def parent; @options[:parent]; end

    ##
    # Parent operator, if any
    #
    # @return [Operator]
    def parent=(operator)
      @options[:parent]= operator
    end

    ##
    # First ancestor operator of type `klass`
    #
    # @param [Class] klass
    # @return [Operator]
    def first_ancestor(klass)
      parent.is_a?(klass) ? parent : parent.first_ancestor(klass) if parent
    end

    ##
    # Validate all operands, operator specific classes should override for operator-specific validation
    # @return [SPARQL::Algebra::Expression] `self`
    # @raise  [ShEx::StructureError] if the value is invalid
    def validate!
      operands.each {|op| op.validate! if op.respond_to?(:validate!)}
      self
    end

    ##
    # A unary operator.
    #
    # Operators of this kind take one operand.
    #
    # @abstract
    class Unary < Operator
      ARITY = 1

      ##
      # @param  [RDF::Term] arg1
      #   the first operand
      # @param  [Hash{Symbol => Object}] options
      #   any additional options (see {Operator#initialize})
      def initialize(arg1, options = {})
        raise ArgumentError, "wrong number of arguments (given 2, expected 1)" unless options.is_a?(Hash)
        super
      end
    end # Unary

    ##
    # A binary operator.
    #
    # Operators of this kind take two operands.
    #
    # @abstract
    class Binary < Operator
      ARITY = 2

      ##
      # @param  [RDF::Term] arg1
      #   the first operand
      # @param  [RDF::Term] arg2
      #   the second operand
      # @param  [Hash{Symbol => Object}] options
      #   any additional options (see {Operator#initialize})
      def initialize(arg1, arg2, options = {})
        raise ArgumentError, "wrong number of arguments (given 3, expected 2)" unless options.is_a?(Hash)
        super
      end
    end # Binary
  end
end