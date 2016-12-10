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
    it {expect {described_class.new(nil, nil)}.to raise_error(ArgumentError, /Found nil operand/)}
    it {expect {described_class.new(ShEx::Algebra::Shape.new, ShEx::Parser.new)}.to raise_error(TypeError, /invalid ShEx::Algebra::Operator/)}
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
    it {expect {described_class.new(nil)}.to raise_error(ArgumentError, /Found nil operand/)}
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
    it {expect {described_class.new(nil, nil)}.to raise_error(ArgumentError, /Found nil operand/)}
    it {expect {described_class.new(ShEx::Algebra::Shape.new, ShEx::Parser.new)}.to raise_error(TypeError, /invalid ShEx::Algebra::Operator/)}
    it {expect {subject}.not_to raise_error}

    it "raises NotSatisfied if all operands do not satisfy" do
      expect {subject.satisfies?(RDF::Node.new).to raise_error(ShEx::NotSatisfied)}
    end

    it "returns true if any operands satisfy" do
      expect(subject.satisfies?(RDF::Literal("foo"))).to be_truthy
      expect(subject.satisfies?(RDF::URI("foo"))).to be_truthy
    end
  end
end
