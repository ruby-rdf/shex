# coding: utf-8
require 'json'
JSON_STATE = JSON::State.new(
   indent:        "  ",
   space:         " ",
   space_before:  "",
   object_nl:     "\n",
   array_nl:      "\n"
 )

RSpec::Matchers.define :generate do |expected, options = {}|
  def parser(options = {})
    @debug = options[:progress] ? 2 : []
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
    "Input        : #{input}\n"
    case expected
    when String
      "Expected     : #{expected}\n"
    else
      "Expected     : #{expected.inspect}\n" +
      "Expected(sse): #{expected.to_sxp}\n"
    end +
    "Actual       : #{actual.inspect}\n" +
    "Actual(sse)  : #{actual.to_sxp}\n" +
    "Processing results:\n#{@debug.is_a?(Array) ? @debug.join("\n") : ''}"
  end
end
