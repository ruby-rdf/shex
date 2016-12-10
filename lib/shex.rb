require 'sparql/extensions'

##
# A ShEx runtime for RDF.rb.
#
# @see https://shexspec.github.io/spec/#shexc
module ShEx
  autoload :Algebra,    'shex/algebra'
  autoload :Meta,       'shex/meta'
  autoload :Parser,     'shex/parser'
  autoload :Terminals,  'shex/terminals'
  autoload :VERSION,    'shex/version'

  ##
  # Parse the given ShEx `query` string.
  #
  # @example parsing a ShExC schema
  #   schema = ShEx.parse(%(
  #     PREFIX ex: <http://schema.example/> ex:IssueShape {ex:state IRI}
  #   ).parse
  #
  # @param  [IO, StringIO, String, #to_s]  expression (ShExC or ShExJ)
  # @param  ['shexc', 'shexj', 'sse']  format ('shexc')
  # @param  [Hash{Symbol => Object}] options
  # @return [ShEx::Algebra::Schema] The executable parsed expression.
  # @raise [ShEx::ParseError] when a syntax error is detected
  # @raise [ShEx::StructureError, ShEx::OperandError] on structural problems with schema
  def self.parse(expression, format: 'shexc', **options)
    case format
    when 'shexc' then Parser.new(expression, options).parse
    when 'shexj'
    when 'sse'
    else raise "Unknown expression format: #{format.inspect}"
    end
  end

  ##
  # Parses input from the given file name or URL.
  #
  # @example parsing a ShExC schema
  #   schema = ShEx.parse('foo.shex').parse
  #
  # @param  [String, #to_s] filename
  # @param  ['shexc', 'shexj', 'sse']  format ('shexc')
  # @param  [Hash{Symbol => Object}] options
  #   any additional options (see `RDF::Reader#initialize` and `RDF::Format.for`)
  # @yield  [ShEx::Algebra::Schema]
  # @yieldparam  [RDF::Reader] reader
  # @yieldreturn [void] ignored
  # @return [ShEx::Algebra::Schema] The executable parsed expression.
  # @raise [ShEx::ParseError] when a syntax error is detected
  # @raise [ShEx::StructureError, ShEx::OperandError] on structural problems with schema
  def self.open(filename, format: 'shexc', **options, &block)
    RDF::Util::File.open_file(filename, options) do |file|
      self.parse(file, options)
    end
  end

  ##
  # Parse and validate the given ShEx `expression` string against `queriable`.
  #
  # @example executing a ShExC schema
  #   graph = RDF::Graph.load("etc/doap.ttl")
  #   ShEx.execute('etc/doap.shex', graph, "http://rubygems.org/gems/shex", "")
  #
  # @param [IO, StringIO, String, #to_s]  expression (ShExC or ShExJ)
  # @param [RDF::Resource] focus
  # @param [RDF::Resource] shape
  # @param ['shexc', 'shexj', 'sse']  format ('shexc')
  # @param [Hash{Symbol => Object}] options
  # @return [Boolean] `true` if satisfied, `false` if it does not apply
  # @raise [ShEx::NotSatisfied] if not satisfied
  # @raise [ShEx::ParseError] when a syntax error is detected
  # @raise [ShEx::StructureError, ShEx::OperandError] on structural problems with schema
  def self.execute(expression, queryable, focus, shape, format: 'shexc', **options, &block)
    shex = self.parse(expression, options)
    queryable = queryable || RDF::Graph.new

    shex.satisfies?(focus, queryable, {focus => shape}, options)
  end

  class Error < StandardError
    # The status code associated with this error
    attr_reader :code

    ##
    # Initializes a new patch error instance.
    #
    # @param  [String, #to_s]          message
    # @param  [Hash{Symbol => Object}] options
    # @option options [Integer]        :code (422)
    def initialize(message, options = {})
      @code = options.fetch(:status_code, 422)
      super(message.to_s)
    end
  end


  # Shape expectation not satisfied
  class StructureError < Error; end

  # Shape expectation not satisfied
  class NotSatisfied < Error; end

  # An error found on an operand
  class OperandError < Error; end

  # Indicates bad syntax found in LD Patch document
  class ParseError < Error
    ##
    # The invalid token which triggered the error.
    #
    # @return [String]
    attr_reader :token

    ##
    # The line number where the error occurred.
    #
    # @return [Integer]
    attr_reader :lineno

    ##
    # Initializes a new parser error instance.
    #
    # @param  [String, #to_s]          message
    # @param  [Hash{Symbol => Object}] options
    # @option options [String]         :token  (nil)
    # @option options [Integer]        :lineno (nil)
    # @option options [Integer]        :code (400)
    def initialize(message, options = {})
      @token      = options[:token]
      @lineno     = options[:lineno] || (@token.lineno if @token.respond_to?(:lineno))
      super(message.to_s, code: options.fetch(:code, 400))
    end
  end
end
