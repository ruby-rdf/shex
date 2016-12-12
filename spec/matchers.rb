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
    begin
      case
      when [ShEx::ParseError, ShEx::StructureError, ArgumentError].include?(expected)
        begin
          parser(options).call(input)
          false
        rescue expected
          true
        end
      when expected.is_a?(Regexp)
        @actual = parser(options).call(input)
        expected.match(@actual.to_sxp)
      when expected.is_a?(String)
        @actual = parser(options).call(input)
        normalize(@actual.to_sxp) == normalize(expected)
      else
        @actual = parser(options).call(input)
        @actual == expected
      end
    rescue
      @actual = $!.message
      false
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

RSpec::Matchers.define :satisfy do |graph, data, focus, shape, map, expected, **options|
  match do |input|
    focus = case focus
    when RDF::Value then focus
    when String
      focus.start_with?("_:") ? RDF::Node(focus[2..-1].to_s) : RDF::URI(focus)
    else
      RDF::Literal(focus)
    end
    shape = RDF::URI(shape)

    case
    when [ShEx::NotSatisfied, ShEx::StructureError].include?(expected)
      begin
        fake_stdout input.satisfies?(focus, graph, (map || {focus => shape}), options)
        false
      rescue expected
        true
      rescue
        false
      end
    else
      begin
        input.satisfies?(focus, graph, (map || {focus => shape}), options)
      rescue Exception => e
        @exception = e
        false
      end
    end

  end

  failure_message do |input|
    (expected == ShEx::NotSatisfied ? "Shape matched" : "Shape did not match: #{@exception.message}\n") +
    "Input(sse): #{SXP::Generator.string(input.to_sxp_bin)}\n" +
    "Data      : #{data}\n" +
    "Shape     : #{shape}\n" +
    "Focus     : #{focus}\n" +
    (options[:logger] ? "Trace     :\n#{options[:logger].to_s}" : "")
  end

  failure_message_when_negated do |input|
    "Shape matched\n" +
    "Input(sse): #{SXP::Generator.string(input.to_sxp_bin)}\n" +
    "Data      : #{data}\n" +
    "Shape     : #{shape}\n" +
    "Focus     : #{focus}\n" +
    (options[:logger] ? "Trace     :\n#{options[:logger].to_s}" : "")
  end
end
