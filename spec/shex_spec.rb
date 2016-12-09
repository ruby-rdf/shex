$:.unshift File.expand_path("../..", __FILE__)
require 'spec_helper'
require 'rdf/util/file'

describe ShEx do
  let(:input) {%(<http://a.example/S1> {})}
  describe ".parse" do
    specify do
      expect(described_class.parse(input)).to be_a(ShEx::Algebra::Schema)
    end
  end

  describe ".open" do
    specify do
      expect(RDF::Util::File).to receive(:open_file).and_yield(StringIO.new(input))
      expect(described_class.open("foo")).to be_a(ShEx::Algebra::Schema)
    end
  end
end

