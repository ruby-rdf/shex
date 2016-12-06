# coding: utf-8
require 'json'
JSON_STATE = JSON::State.new(
   indent:        "  ",
   space:         " ",
   space_before:  "",
   object_nl:     "\n",
   array_nl:      "\n"
 )

 def parser(options = {})
   @debug = options[:progress] ? 2 : (options[:quiet] ? false : [])
   Proc.new do |input|
     parser = ShEx::Parser.new(input, {debug: @debug, resolve_iris: false}.merge(options))
     options[:production] ? parser.parse(options[:production]) : parser.parse
   end
 end

 def normalize(obj)
   if obj.is_a?(String)
     obj.gsub(/\s+/m, ' ').
       gsub(/\s+\)/m, ')').
       gsub(/\(\s+/m, '(').
       strip
   else
     obj
   end
 end

RSpec::Matchers.define :generate do |expected, options = {}|
  match do |input|
    case
    when expected == ShEx::ParseError
      expect {parser(options).call(input)}.to raise_error(expected)
    when expected.is_a?(Regexp)
      @actual = parser(options).call(input)
      expect(normalize(@actual.to_sxp)).to match(expected)
    when expected.is_a?(String)
      @actual = parser(options).call(input)
      expect(normalize(@actual.to_sxp)).to eq normalize(expected)
    else
      @actual = parser(options).call(input)
      expect(@actual).to eq expected
    end
  end
  
  failure_message do |input|
    "Input        : #{input}\n" +
    case expected
    when String
      "Expected     : #{expected}\n"
    else
      "Expected     : #{expected.inspect}\n" +
      "Expected(sse): #{SXP::Generator.string(expected.to_sxp_bin)}\n"
    end +
    "Actual       : #{actual.inspect}\n" +
    "Actual(sse)  : #{SXP::Generator.string(actual.to_sxp_bin)}\n" +
    "Processing results:\n#{@debug.is_a?(Array) ? @debug.join("\n") : ''}"
  end
end

RSpec::Matchers.define :satisfy do |graph, data, focus, shape, map = nil|
  match do |input|
    focus = case focus
    when RDF::Value then focus
    when String
      RDF::URI("http://example.com/").join(RDF::URI(focus))
    else
      RDF::Literal(focus)
    end
    shape = RDF::URI(shape)

    input.satisfies?(focus, graph, (map || {focus => shape}))
  end

  failure_message do |input|
    "Input(sse)   : #{SXP::Generator.string(input.to_sxp_bin)}\n" +
    "Data         : #{data}\n" +
    "Shape        : #{shape}\n" +
    "Focus        : #{focus}\n"
  end

  failure_message do |input|
    "Shape did not match\n" +
    "Input(sse)   : #{SXP::Generator.string(input.to_sxp_bin)}\n" +
    "Data         : #{data}\n" +
    "Shape        : #{shape}\n" +
    "Focus        : #{focus}\n"
  end

  failure_message_when_negated do |input|
    "Shape matched\n" +
    "Input(sse)   : #{SXP::Generator.string(input.to_sxp_bin)}\n" +
    "Data         : #{data}\n" +
    "Shape        : #{shape}\n" +
    "Focus        : #{focus}\n"
  end
end
