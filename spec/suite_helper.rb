require 'rdf/turtle'
require 'json/ld'

module Fixtures
  module SuiteTest
    BASE = File.expand_path("../shexTest", __FILE__) + '/'

    class Manifest < JSON::LD::Resource
      attr_accessor :file

      def self.open(file)
        #puts "open: #{file}"
        @file = file
        json = JSON.parse(File.read(@file))
        yield Manifest.new(json['@graph'].first)
      end

      def entries
        # Map entries to resources
        attributes['entries'].map {|e| Entry.new(e, base: file)}
      end
    end

    class Entry < JSON::LD::Resource
      attr_accessor :debug

      def schema
        action.is_a?(Hash) && (BASE + 'validation/' + action["schema"])
      end

      def data
        action.is_a?(Hash) && (BASE + 'validation/' + action["data"])
      end

      def result
        BASE + 'validation/' + attributes['result']
      end

      def shape
        action.is_a?(Hash) && action["shape"]
      end

      def focus
        action.is_a?(Hash) && action["focus"]
      end

      def turtle
        @turtle ||= File.read(data)
      end

      def graph
        @graph ||= RDF::Graph.load(data, base_uri: base)
      end

      def schema_source
        @schema_source ||= File.read(schema)
      end

      def positive_test?
        Array(attributes['@type']).join(" ").match(/ValidationTest/)
      end

      def negative_test?
        !positive_test?
      end

      # Create a logger initialized with the content of `debug`
      def logger
        @logger ||= begin
          l = RDF::Spec.logger
          debug.each {|d| l.debug(d)}
          l
        end
      end

      def inspect
        super.sub('>', "\n" +
        "  positive?: #{positive_test?.inspect}\n" +
        ">"
      )
      end
    end
  end
end