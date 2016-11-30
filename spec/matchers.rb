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

RSpec::Matchers.define :satisfy do |expected, options = {}|
  match do |input|
    decls = 'BASE <http://example.com/> PREFIX ex: <http://schema.example/> ' + 
    graph = RDF::Graph.new {|g| RDF::Turtle::Reader.new(decls + input) {|r| g << r}}
    @expression = parser(quiet: true).call(decls + expected)

    @expression.execute(graph)
  end
  
  failure_message do |input|
    "Input        : #{input}\n" +
    "Input(sse)   : #{SXP::Generator.string(@expression.to_sxp_bin)}\n" +
    "Processing results:\n#{@debug.is_a?(Array) ? @debug.join("\n") : ''}"
  end
end
