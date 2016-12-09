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
  # @example
  #   query = ShEx.parse("...")
  #
  # @param  [IO, StringIO, String, #to_s]  expression (ShExC or ShExJ)
  # @param  ['shexc', 'shexj', 'sse']  format ('shexc')
  # @param  [Hash{Symbol => Object}] options
  # @return [ShEx::Algebra::Operator] The executable parsed expression.
  # @raise  [Parser::Error] on invalid input
  def self.parse(expression, format: 'shexc', **options)
    case format
    when 'shexc' then Parser.new(expression, options).parse
    when 'shexj'
    when 'sse'
    else raise "Unknown expression format: #{format.inspect}"
    end
  end

  ##
  # Parse and execute the given ShEx `expression` string against `queriable`.
  # @param  [IO, StringIO, String, #to_s]  expression (ShExC or ShExJ)
  # @param  ['shexc', 'shexj', 'sse']  format ('shexc')
  # @param  [Hash{Symbol => Object}] options
  def self.execute(expression, queryable, format: 'shexc', **options, &block)
    shex = self.parse(expression, options)
    queryable = queryable || RDF::Graph.new

    shex.execute(queryable, options)
  rescue Parser::Error => e
    raise MalformedQuery, e.message
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
