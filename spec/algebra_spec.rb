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

  describe ShEx::Algebra::SemAct do
    subject {described_class.new(RDF::URI("http://example/TestAct"), "foo")}
    let(:implementation) {double("implementation")}
    let(:schema) {double("schema", extensions: {"http://example/TestAct" => implementation})}
    before {allow(subject).to receive(:schema).and_return(schema)}

    describe "#enter" do
      it "enters implementation" do
        expect(implementation).to receive(:enter)
        subject.enter
      end
    end

    describe "#exit" do
      it "exits implementation" do
        expect(implementation).to receive(:exit)
        subject.exit
      end
    end

    describe "#satisfies?" do
      it "visits implementation with nothing matched" do
        expect(implementation).to receive(:visit).with(code: "foo", expression: nil, depth: 0).and_return(true)
        subject.satisfies?(nil, matched: [])
      end

      it "visits implementation and raises error with nothing matched" do
        expect(implementation).to receive(:visit).with(code: "foo", expression: nil, depth: 0).and_return(false)
        expect {subject.satisfies?(nil, matched: [])}.to raise_error(ShEx::NotSatisfied)
      end

      it "visits implementation all matched statements" do
        expect(implementation).to receive(:visit).with(code: "foo", matched: anything, expression: nil, depth: 0).and_return(true, true)
        subject.satisfies?(nil, matched: %w(a b))
      end

      it "visits implementation all matched statements and raises error" do
        expect(implementation).to receive(:visit).with(code: "foo", matched: anything, expression: nil, depth: 0).and_return(true, false)
        expect {subject.satisfies?(nil, matched: %w(a b))}.to raise_error(ShEx::NotSatisfied)
      end
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
        shexc: %{(tripleConstraint (predicate a))}
      },
      "1length" => {
        shexj: %({
          "type": "TripleConstraint",
          "predicate": "http://a.example/p1",
          "valueExpr": { "type": "NodeConstraint", "length": 5 }
        }),
        shexc: %{(tripleConstraint (predicate <http://a.example/p1>) (nodeConstraint (length 5)))}
      }
    }.each do |name, params|
      it name do
        expect(params[:shexj]).to generate(params[:shexc], format: :shexj)
      end
    end
  end
end
