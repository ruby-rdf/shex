require 'rdf/spec'
require 'rdf/turtle'
require 'json/ld'

# For now, override RDF::Utils::File.open_file to look for the file locally before attempting to retrieve it
module RDF::Util
  module File
    REMOTE_PATH = "https://raw.githubusercontent.com/shexSpec/shexTest/master/"
    LOCAL_PATH = ::File.expand_path("../shexTest", __FILE__) + '/'

    class << self
      alias_method :original_open_file, :open_file
    end

    ##
    # Override to use Patron for http and https, Kernel.open otherwise.
    #
    # @param [String] filename_or_url to open
    # @param  [Hash{Symbol => Object}] options
    # @option options [Array, String] :headers
    #   HTTP Request headers.
    # @return [IO] File stream
    # @yield [IO] File stream
    def self.open_file(filename_or_url, **options, &block)
      case 
      when filename_or_url.to_s =~ /^file:/
        path = filename_or_url[5..-1]
        Kernel.open(path.to_s, options, &block)
      when (filename_or_url.to_s =~ %r{^#{REMOTE_PATH}} && Dir.exist?(LOCAL_PATH))
        #puts "attempt to open #{filename_or_url} locally"
        localpath = filename_or_url.to_s.sub(REMOTE_PATH, LOCAL_PATH)
        response = begin
          ::File.open(localpath)
        rescue Errno::ENOENT => e
          raise IOError, e.message
        end
        document_options = {
          base_uri:     RDF::URI(filename_or_url),
          charset:      Encoding::UTF_8,
          code:         200,
          headers:      {}
        }
        #puts "use #{filename_or_url} locally"
        document_options[:headers][:content_type] = case filename_or_url.to_s
        when /\.ttl$/    then 'text/turtle'
        when /\.nt$/     then 'application/n-triples'
        when /\.jsonld$/ then 'application/ld+json'
        else                  'unknown'
        end

        document_options[:headers][:content_type] = response.content_type if response.respond_to?(:content_type)
        # For overriding content type from test data
        document_options[:headers][:content_type] = options[:contentType] if options[:contentType]

        remote_document = RDF::Util::File::RemoteDocument.new(response.read, **document_options)
        if block_given?
          yield remote_document
        else
          remote_document
        end
      else
        original_open_file(filename_or_url, **options, &block)
      end
    end
  end
end

module Fixtures
  module SuiteTest
    BASE = "https://raw.githubusercontent.com/shexSpec/shexTest/master/"

    class Manifest < JSON::LD::Resource
      attr_accessor :file

      def self.open(file)
        #puts "open: #{file}"
        @file = file

        # Create a manifest, if `file` doesn't exist
        json = JSON.parse(RDF::Util::File.open_file(file.to_s).read)
        man = Manifest.new(json['@graph'].first, json: json, context: {base: file.to_s})
        man.instance_variable_set(:@json, json)
        yield man
      end

      def entries
        # Map entries to resources
        ents = attributes['entries'].map {|e| Entry.new(e, context: context)}
        ents
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

      def ttl
        attributes["ttl"] && base.join(attributes["ttl"])
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

      def trait
        Array(attributes["trait"])
      end

      def map
        action.is_a?(Hash) && action["map"] && base.join(action["map"])
      end

      def shape_map
        @shape_map ||= JSON.parse(RDF::Util::File.open_file(map, &:read))
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
        @turtle_source ||= RDF::Util::File.open_file(ttl, &:read)
      end

      def results
        @results ||= (JSON.parse(RDF::Util::File.open_file(result, &:read)) if attributes['result'])
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