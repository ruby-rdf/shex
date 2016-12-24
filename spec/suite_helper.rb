require 'rdf/spec'
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

        # Create a manifest, if `file` doesn't exist
        json = if File.exist?(file)
          JSON.parse(File.read(file))
        else
          generate_manifest(file,
                            structure: file.downcase.include?('structure'),
                            negative: file.include?('negative'))
        end
        man = Manifest.new(json['@graph'].first, json: json, context: {base: "file:/#{file}"})
        man.instance_variable_set(:@json, json)
        yield man
      end

      def entries
        # Map entries to resources
        ents = attributes['entries'].map {|e| Entry.new(e, context: context)}
        ents
      end

      def self.generate_manifest(file, structure:, negative:)
        dir = file.split('/')[0..-2].compact.join('/')
        man = JSON.parse(%({
          "@context": "https://raw.githubusercontent.com/shexSpec/shexTest/master/context.jsonld",
          "@graph": [{
            "@id": "https://raw.githubusercontent.com/shexSpec/shexTest/master/#{dir.split('/').last}/manifest",
            "@type": "mf:Manifest",
            "rdfs:comment": "ShEx#{negative ? " negative" : ""} #{structure ? "structure" : "syntax"} tests",
            "entries": []
          }]
        }))
        entries = man['@graph'][0]['entries']
        Dir.glob("#{dir}/*.shex").each do |f|
          shex = f.split('/').last
          name = shex.sub(/\.shex$/, '')
          json = shex.sub('.shex', '.json') if File.exist?(f.sub('.shex', '.json'))
          entry = {
            "@id" => "##{name}",
            "@type" => "sht:#{negative ? "Negative" : ""}#{structure ? "Structure" : "Syntax"}Test",
            "name" => name,
            "shex" => shex
          }
          entry['json'] = json if json
          entries << entry
        end
        man
      end
    end

    class Entry < JSON::LD::Resource
      attr_accessor :debug

      def base
        RDF::URI(context[:base])
      end

      def schema
        base.join(action.is_a?(Hash) && action["schema"] ? action["schema"] : shex)
      end

      def json
        sch = action["schema"].to_s.sub('.shex', '.json') if action.is_a?(Hash) && action["schema"]
        base.join(attributes.fetch('json', sch))
      end

      def data
        action.is_a?(Hash) && action["data"] && base.join(action["data"])
      end

      def turtle
        attributes["turtle"] && base.join(attributes["turtle"])
      end

      def shapeExterns
        action.is_a?(Hash) && action["shapeExterns"] && [base.join(action["shapeExterns"])]
      end

      def result
        base.join(attributes['result'])
      end

      def shape
        action.is_a?(Hash) && action["shape"]
      end

      def focus
        action.is_a?(Hash) && action["focus"]
      end

      def graph
        @graph ||= RDF::Graph.load(data, base_uri: base)
      end

      def schema_source
        @schema_source ||= RDF::Util::File.open_file(schema, &:read)
      end

      def schema_json
        @schema_json ||= RDF::Util::File.open_file(json, &:read)
      end

      def data_source
        @data_source ||= RDF::Util::File.open_file(data, &:read)
      end

      def turtle_source
        @turtle_source ||= RDF::Util::File.open_file(turtle, &:read)
      end

      def structure_test?
        !!Array(attributes['@type']).join(" ").match(/Structure/)
      end

      def syntax_test?
        !!Array(attributes['@type']).join(" ").match(/Syntax/)
      end

      def validation_test?
        !!Array(attributes['@type']).join(" ").match(/Validation/)
      end

      def positive_test?
        !negative_test?
      end

      def negative_test?
        !!Array(attributes['@type']).join(" ").match(/Negative|Failure/)
      end

      # Create a logger initialized with the content of `debug`
      def logger
        @logger ||= begin
          l = RDF::Spec.logger
          (debug || []).each {|d| l.debug(d)}
          l
        end
      end

      def inspect
        "<Entry\n" + attributes.map do |k,v|
          case v when Hash
            "  #{k}: {\n" + v.map {|ak, av| "    #{ak}: #{av.inspect}"}.join(",\n") + "\n  }"
          else
            " #{k}: #{v.inspect}"
          end
        end.join("  \n") + ">"
      end
    end
  end
end