$:.unshift File.expand_path("../..", __FILE__)
require 'spec_helper'

describe ShEx::Algebra do
  before(:each) {$stderr = StringIO.new}
  after(:each) {$stderr = STDERR}
  let(:logger) {RDF::Spec.logger}
  let(:schema) {double("Schema", graph: RDF::Graph.new)}
  before(:each) {allow_any_instance_of(ShEx::Algebra::Operator).to receive(:schema).and_return(schema)}

  describe ShEx::Algebra::And do
    subject {described_class.new(ShEx::Algebra::Shape.new, ShEx::Algebra::NodeConstraint.new(:iri))}
    it {expect {described_class.new}.to raise_error(ArgumentError, /wrong number of arguments/)}
    it {expect {described_class.new(ShEx::Algebra::Shape.new)}.to raise_error(ArgumentError, /wrong number of arguments/)}
    it {expect {described_class.new(nil, nil)}.to raise_error(ArgumentError, /All operands must be Shape/)}
    it {expect {described_class.new(ShEx::Algebra::Shape.new, ShEx::Algebra::TripleConstraint.new)}.to raise_error(ArgumentError, /All operands must be Shape/)}
    it {expect {subject}.not_to raise_error}

    it "raises NotSatisfied if any operand does not satisfy" do
      expect {subject.satisfies?(RDF::Literal("foo")).to raise_error(ShEx::NotSatisfied)}
    end

    it "returns true if all operands satisfy" do
      expect(subject.satisfies?(RDF::URI("foo"))).to be_truthy
    end
  end

  describe ShEx::Algebra::Not do
    subject {described_class.new(ShEx::Algebra::NodeConstraint.new(:literal))}
    it {expect {described_class.new}.to raise_error(ArgumentError, /wrong number of arguments/)}
    it {expect {described_class.new(ShEx::Algebra::Shape.new, ShEx::Algebra::Shape.new)}.to raise_error(ArgumentError, /wrong number of arguments/)}
    it {expect {described_class.new(ShEx::Parser.new)}.to raise_error(TypeError, /invalid ShEx::Algebra::Operator/)}
    it {expect {subject}.not_to raise_error}

    it "raises NotSatisfied if operand satisfies" do
      expect {subject.satisfies?(RDF::Literal("foo")).to raise_error(ShEx::NotSatisfied)}
    end

    it "returns true if operands does not satisfy" do
      expect(subject.satisfies?(RDF::URI("foo"))).to be_truthy
    end
  end

  describe ShEx::Algebra::Or do
    subject {described_class.new(ShEx::Algebra::NodeConstraint.new(:literal), ShEx::Algebra::NodeConstraint.new(:iri))}
    it {expect {described_class.new}.to raise_error(ArgumentError, /wrong number of arguments/)}
    it {expect {described_class.new(ShEx::Algebra::Shape.new)}.to raise_error(ArgumentError, /wrong number of arguments/)}
    it {expect {described_class.new(nil, nil)}.to raise_error(ArgumentError, /All operands must be Shape/)}
    it {expect {described_class.new(ShEx::Algebra::Shape.new, ShEx::Parser.new)}.to raise_error(ArgumentError, /All operands must be Shape/)}
    it {expect {subject}.not_to raise_error}

    it "raises NotSatisfied if all operands do not satisfy" do
      expect {subject.satisfies?(RDF::Node.new).to raise_error(ShEx::NotSatisfied)}
    end

    it "returns true if any operands satisfy" do
      expect(subject.satisfies?(RDF::Literal("foo"))).to be_truthy
      expect(subject.satisfies?(RDF::URI("foo"))).to be_truthy
    end
  end

  subject {described_class.new(RDF.type)}

  describe ".from_shexj" do
    {
      "0" => {
        shexj: %({"type": "Shape"}),
        shexc: %{(shape)}
      },
      "1Adot" => {
        shexj: %({ "type": "TripleConstraint", "predicate": "http://www.w3.org/1999/02/22-rdf-syntax-ns#type"}),
        shexc: %{(tripleConstraint a)}
      },
      "1length" => {
        shexj: %({
          "type": "TripleConstraint",
          "predicate": "http://a.example/p1",
          "valueExpr": { "type": "NodeConstraint", "length": 5 }
        }),
        shexc: %{(tripleConstraint <http://a.example/p1> (nodeConstraint (length 5)))}
      }
    }.each do |name, params|
      it name do
        expect(params[:shexj]).to generate(params[:shexc], format: :shexj)
      end
    end
  end
end
