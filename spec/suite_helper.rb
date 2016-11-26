require 'rdf/turtle'
require 'json/ld'

module Fixtures
  module SuiteTest
    BASE = "shexTest/"

    class Manifest < JSON::LD::Resource
      def self.open(file)
        #puts "open: #{file}"
        prefixes = {}
        g = RDF::Repository.load(file, format:  :ttl)
        JSON::LD::API.fromRDF(g) do |expanded|
          JSON::LD::API.frame(expanded, FRAME) do |framed|
            yield Manifest.new(framed['@graph'].first)
          end
        end
      end

      # @param [Hash] json framed JSON-LD
      # @return [Array<Manifest>]
      def self.from_jsonld(json)
        json['@graph'].map {|e| Manifest.new(e)}
      end

      def entries
        # Map entries to resources
        attributes['entries'].map {|e| Entry.new(e, base: file)}
      end
    end

    class Entry < JSON::LD::Resource
      attr_accessor :debug

      def base
        action.is_a?(Hash) ? action.fetch("base", action["data"]) : action
      end

      # Alias data and query
      def input
        url = case action
        when Hash then action['patch']
        else action
        end
        @input ||= RDF::Util::File.open_file(URI.decode(url)) {|f| f.read}
      end

      def data
        action.is_a?(Hash) && action["data"]
      end

      def target_graph
        @graph ||= RDF::Graph.load(URI.decode(data), base_uri: base)
      end

      def expected
        @expected ||= RDF::Util::File.open_file(URI.decode(result)) {|f| f.read}
      end

      def expected_graph
        @expected_graph ||= RDF::Graph.load(URI.decode(result), base_uri: base)
      end

      def evaluate?
        Array(attributes['@type']).join(" ").match(/Eval/)
      end

      def syntax?
        Array(attributes['@type']).join(" ").match(/Syntax/)
      end

      def positive_test?
        !Array(attributes['@type']).join(" ").match(/Negative/)
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
        "  syntax?: #{syntax?.inspect}\n" +
        "  positive?: #{positive_test?.inspect}\n" +
        "  evaluate?: #{evaluate?.inspect}\n" +
        ">"
      )
      end
    end
  end
end