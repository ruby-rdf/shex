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
    # Returns the SPARQL S-Expression (SSE) representation of this operator.
    #
    # @return [Array]
    # @see    http://openjena.org/wiki/SSE
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