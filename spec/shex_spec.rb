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
end

