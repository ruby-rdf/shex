# coding: utf-8
require 'json'
JSON_STATE = JSON::State.new(
   indent:        "  ",
   space:         " ",
   space_before:  "",
   object_nl:     "\n",
   array_nl:      "\n"
 )

 def parser(**options)
   Proc.new do |input|
     case options[:format]
     when :shexj
       ShEx::Algebra.from_shexj(JSON.parse input)
     else
       parser = ShEx::Parser.new(input, **options)
       options[:production] ? parser.parse(options[:production]) : parser.parse
     end
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

RSpec::Matchers.define :generate do |expected, **options|
  match do |input|
    @input = input
    begin
      case
      when [ShEx::ParseError, ShEx::StructureError, ArgumentError, StandardError].include?(expected)
        begin
           @actual = parser(**options).call(input)
          false
        rescue expected
          true
        end
      when expected.is_a?(Regexp)
        @actual = parser(**options).call(input)
        expected.match(@actual.to_sxp)
      when expected.is_a?(String)
        @actual = parser(**options).call(input)
        normalize(@actual.to_sxp) == normalize(expected)
      else
        @actual = parser(**options).call(input)
        @actual == expected
      end
    rescue
      @actual = $!.message
      options[:logger].info "Backtrace:\n#{$!.backtrace.join("\n")}" if options[:logger]
      false
    end
  end

  failure_message do |input|
    "Input        : #{@input}\n" +
    case expected
    when String
      "Expected     : #{expected}\n"
    else
      "Expected     : #{expected.inspect}\n" +
      "Expected(sxp): #{SXP::Generator.string(expected.to_sxp_bin)}\n"
    end +
    "Actual       : #{actual.inspect}\n" +
    "Actual(sxp)  : #{SXP::Generator.string(actual.to_sxp_bin)}\n" +
    (options[:logger] ? "Trace     :\n#{options[:logger].to_s}" : "")
  end

  failure_message_when_negated do |input|
    "Input        : #{@input}\n" +
    case expected
    when String
      "Expected     : #{expected}\n"
    else
      "Expected     : #{expected.inspect}\n" +
      "Expected(sxp): #{SXP::Generator.string(expected.to_sxp_bin)}\n"
    end +
    "Actual       : #{actual.inspect}\n" +
    "Actual(sxp)  : #{SXP::Generator.string(actual.to_sxp_bin)}\n" +
    (options[:logger] ? "Trace     :\n#{options[:logger].to_s}" : "")
  end
end

RSpec::Matchers.define :satisfy do |graph, data, map, focus: nil, expected: nil, logger: nil, expected_results: nil, **options|
  match do |input|
    shape_results = nil

    res = case
    when [ShEx::NotSatisfied, ShEx::StructureError].include?(expected)
      begin
        shape_results = input.execute(graph, map, focus: focus, logger: logger, **options)
        false
      rescue expected => e
        shape_results = e.expression if e.respond_to?(:expression) && e.expression.is_a?(Hash)
        true
      end
    else
      begin
        shape_results = input.execute(graph, map, focus: focus, logger: logger, **options)
        true
      rescue ShEx::NotSatisfied => e
        @exception = e
        shape_results = e.expression
        false
      end
    end

    @results = (shape_results || {}).inject({}) do |memo, (k, vv)|
      memo.merge(k.to_s => vv.map {|v| {"shape" => v.shape.to_s, "result" => v.result}})
    end

    res # && (expected_results.nil? || results == @results) # FIXME work on result representation
  end

  failure_message do |input|
    (expected == ShEx::NotSatisfied ? "Unexpected match\n" : "Shape did not match: #{@exception && @exception.message}\n") +
    "Input(sxp): #{SXP::Generator.string(input.to_sxp_bin)}\n" +
    "Data      : #{data}\n" +
    "Focus     : #{focus}\n" +
    "Expected  : #{(expected_results || expected).inspect}\n" +
    "Results   : #{@results.inspect if @results}\n" +
    (logger ? "Trace     :\n#{logger.to_s}" : "")
  end

  failure_message_when_negated do |input|
    "Unexpected match\n" +
    "Input(sxp): #{SXP::Generator.string(input.to_sxp_bin)}\n" +
    "Data      : #{data}\n" +
    "Focus     : #{focus}\n" + +
    "Expected  : #{(expected_results || expected).inspect}\n" +
    "Results   : #{@results.inspect if @results}\n" +
    (logger ? "Trace     :\n#{logger.to_s}" : "")
  end
end
