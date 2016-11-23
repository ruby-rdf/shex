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
  # @param  [IO, StringIO, String, #to_s]  expression
  # @param  [Hash{Symbol => Object}] options
  # @return [ShEx::Algebra::Operator] The executable parsed expression.
  # @raise  [Parser::Error] on invalid input
  def self.parse(expression, options = {})
    Parser.new(expression, options).parse
  end

  ##
  # Parse and execute the given ShEx `expression` string against `queriable`.
  def self.execute(expression, queryable, options = {}, &block)
    query = self.parse(expression, options)
    queryable = queryable || RDF::Repository.new

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
