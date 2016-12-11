$:.unshift File.expand_path("../..", __FILE__)
require 'spec_helper'
require 'rdf/util/file'

describe ShEx do
  let(:input) {%(<http://a.example/S1> {})}
  describe ".parse" do
    specify do
      expect(described_class.parse(input)).to be_a(ShEx::Algebra::Schema)
    end

    it "detects bad format" do
      expect {described_class.parse(input, format: :foo)}.to raise_error(/Unknown expression format/)
    end
  end

  describe ".open" do
    specify do
      expect(RDF::Util::File).to receive(:open_file).and_yield(StringIO.new(input))
      expect(described_class.open("foo")).to be_a(ShEx::Algebra::Schema)
    end

    it "detects bad format" do
      expect(RDF::Util::File).to receive(:open_file).and_yield(StringIO.new(input))
      expect {described_class.open("foo", format: :foo)}.to raise_error(/Unknown expression format/)
    end
  end

  describe ".execute" do
    specify do
      expect(described_class.execute(input, nil, RDF::URI("http://example/foo"), RDF::URI("http://a.example/S1"))).to be_truthy
    end
  end

  context "README" do
    let(:doap_shex) {File.expand_path("../../etc/doap.shex", __FILE__)}
    let(:doap_ttl) {File.expand_path("../../etc/doap.ttl", __FILE__)}
    let(:doap_subj) {RDF::URI("http://rubygems.org/gems/shex")}
    let(:doap_shape) {RDF::URI("TestShape")}
    it "parses doap.shex" do
      doap_sxp = %{(schema
       (prefix (("doap" <http://usefulinc.com/ns/doap#>) ("dc" <http://purl.org/dc/terms/>)))
       (shapes
        ((<TestShape> (shape
           (eachOf
            (tripleConstraint a (nodeConstraint (value <http://usefulinc.com/ns/doap#Project>)))
            (oneOf
             (eachOf
              (tripleConstraint <http://usefulinc.com/ns/doap#name> (nodeConstraint literal))
              (tripleConstraint <http://usefulinc.com/ns/doap#description>
               (nodeConstraint literal)) )
             (eachOf
              (tripleConstraint <http://purl.org/dc/terms/title> (nodeConstraint literal))
              (tripleConstraint <http://purl.org/dc/terms/description> (nodeConstraint literal)))
             (min 1) (max "*"))
            (tripleConstraint <http://usefulinc.com/ns/doap#category>
             (nodeConstraint iri)
             (min 0) (max "*"))
            (tripleConstraint <http://usefulinc.com/ns/doap#developer>
             (nodeConstraint iri)
             (min 1) (max "*"))
            (tripleConstraint <http://usefulinc.com/ns/doap#implements>
             (nodeConstraint (value <https://shexspec.github.io/spec/>))) )
           (extra a))))))}
      expect(File.read(doap_shex)).to generate(doap_sxp)
    end

    it "validates doap.ttl" do
      graph = RDF::Graph.load(doap_ttl)
      schema = ShEx.open(doap_shex)
      expect(schema).to satisfy(graph, File.read(doap_ttl), doap_subj, doap_shape, logger: RDF::Spec.logger)
    end
  end
end

