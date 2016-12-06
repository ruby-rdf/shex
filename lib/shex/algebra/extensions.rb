require 'rdf'

##
# Extensions for `RDF::Value`
module RDF::Value
  ##
  # Returns `true` if this Value starts with the given `string`.
  #
  # @example
  #   RDF::URI('http://example.org/').start_with?('http')     #=> true
  #   RDF::Node('_:foo').start_with?('_:bar')                 #=> false
  #   RDF::Litera('Apple').start_with?('Orange')              #=> false
  #
  # @param  [String, #to_s] string
  # @return [Boolean] `true` or `false`
  # @see    String#start_with?
  # @since  0.3.0
  def start_with?(string)
    to_s.start_with?(string.to_s)
  end
  alias_method :starts_with?, :start_with?
end
