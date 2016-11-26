require 'sparql/algebra'
require 'sparql/extensions'

module ShEx::Algebra

  ##
  # The ShEx operator.
  #
  # @abstract
  class Operator
    extend SPARQL::Algebra::Expression

    ##
    # Returns an operator class for the given operator `name`.
    #
    # @param  [Symbol, #to_s]  name
    # @param  [Integer] arity
    # @return [Class] an operator class, or `nil` if an operator was not found
    def self.for(name, arity = nil)
      {
        and: And,
        base: Base,
        nodeConstraint: NodeConstraint,
        not: Not,
        or: Or,
        prefix: Prefix,
        schema: Schema,
        shape_definition: ShapeDefinition,
        shape_ref: ShapeRef,
        shape: Shape,
        tripleConstraint: TripleConstraint,
        unaryShape: UnaryShape,
      }.fetch(name.to_s.downcase.to_sym)
    end

    ##
    # Returns the arity of this operator class.
    #
    # @example
    #   Operator.arity           #=> -1
    #   Operator::Nullary.arity  #=> 0
    #   Operator::Unary.arity    #=> 1
    #   Operator::Binary.arity   #=> 2
    #   Operator::Ternary.arity  #=> 3
    #
    # @return [Integer] an integer in the range `(-1..3)`
    def self.arity
      self.const_get(:ARITY)
    end

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
            operand.each {|op| op.parent = self if operand.respond_to?(:parent=)}
            operand
          when Operator, RDF::Term, RDF::Query, RDF::Query::Pattern, Array, Symbol
            operand.parent = self if operand.respond_to?(:parent=)
            operand
          when TrueClass, FalseClass, Numeric, String, DateTime, Date, Time
            RDF::Literal(operand)
          when NilClass
            nil
          else raise TypeError, "invalid SPARQL::Algebra::Operator operand: #{operand.inspect}"
        end
      end
    end

    ##
    # Base URI used for reading data sources with relative URIs
    #
    # @return [RDF::URI]
    def base_uri
      Operator.base_uri
    end

    ##
    # Base URI used for reading data sources with relative URIs
    #
    # @return [RDF::URI]
    def self.base_uri
      @base_uri
    end

    ##
    # Set Base URI associated with SPARQL document, typically done
    # when reading SPARQL from a URI
    #
    # @param [RDF::URI] uri
    # @return [RDF::URI]
    def self.base_uri=(uri)
      @base_uri = RDF::URI(uri)
    end

    ##
    # Prefixes useful for future serialization
    #
    # @return [Hash{Symbol => RDF::URI}]
    #   Prefix definitions
    def prefixes
      Operator.prefixes
    end

    ##
    # Prefixes useful for future serialization
    #
    # @return [Hash{Symbol => RDF::URI}]
    #   Prefix definitions
    def self.prefixes
      @prefixes
    end

    ##
    # Prefixes useful for future serialization
    #
    # @param [Hash{Symbol => RDF::URI}] hash
    #   Prefix definitions
    # @return [Hash{Symbol => RDF::URI}]
    def self.prefixes=(hash)
      @prefixes = hash
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
      # @param  [RDF::Term] arg2
      #   the second operand
      # @param  [Hash{Symbol => Object}] options
      #   any additional options (see {Operator#initialize})
      def initialize(arg1, options = {})
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
        super
      end
    end # Binary
  end
end