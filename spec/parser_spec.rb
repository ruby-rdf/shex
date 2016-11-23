$:.unshift File.expand_path("../..", __FILE__)
require 'spec_helper'

describe ShEx do
  describe ".parse" do
    specify do
      input = %(<http://a.example/S1> {})
      expect(described_class.parse(input)).to be_a(ShEx::Algebra::Operator)
    end
  end
end

describe ShEx::Parser do
  before(:each) {$stderr = StringIO.new}
  after(:each) {$stderr = STDERR}

  describe "#initialize" do
    it "accepts a string query" do |example|
      expect {
        described_class.new("foo") {
          raise "huh" unless input == "foo"
        }
      }.not_to raise_error
    end

    it "accepts a StringIO query" do |example|
      expect {
        described_class.new(StringIO.new("foo")) {
          raise "huh" unless input == "foo"
        }
      }.not_to raise_error
    end
  end

  describe "Empty" do
    it "renders an empty Schema" do
      expect("").to generate("(Schema)")
    end
  end

  describe "Add" do
    {
      "add-1triple" => {
        input: %(Add { <http://example.org/s2> <http://example.org/p2> <http://example.org/o2> } .),
        result: %((patch (add ((triple <http://example.org/s2> <http://example.org/p2> <http://example.org/o2>)))))
      },
      "add-abbr-1triple" => {
        input: %(A { <http://example.org/s2> <http://example.org/p2> <http://example.org/o2> } .),
        result: %((patch (add ((triple <http://example.org/s2> <http://example.org/p2> <http://example.org/o2>)))))
      },
      "addnew-1triple" => {
        input: %(AddNew { <http://example.org/s2> <http://example.org/p2> <http://example.org/o2> } .),
        result: %((patch (add ((triple <http://example.org/s2> <http://example.org/p2> <http://example.org/o2>)))))
      },
      "addnew-abbr-1triple" => {
        input: %(AN { <http://example.org/s2> <http://example.org/p2> <http://example.org/o2> } .),
        result: %((patch (add ((triple <http://example.org/s2> <http://example.org/p2> <http://example.org/o2>)))))
      },
    }.each do |name, params|
      it name do
        expect(params[:input]).to generate(params[:result])
      end
    end
  end

  describe "Syntax" do
    {
      "0" => {
        shexc: %(<http://a.example/S1> {}),
        shexj: %({
          "type": "Schema",
          "shapes":{
            "http://a.example/S1": {
              "type": "Shape"
            }
          }
        }),
        sxp: %{(Schema
          '(<http://a.example/S1>
              (EmptyRule) )
          )}
      },
    }.each do |name, params|
      it name do
        expect(params[:input]).to generate(params[:result])
      end
    end
  end

  describe "NegativeSyntax" do
    {
      "1valA.shex" => {
        input: %(<http://a.example/IssueShape> {
           <http://a.example/p1> (a)
        }),
        result: ShEx::ParseError
      },
    }.each do |name, params|
      it name do
        expect(params[:input]).to generate(params[:result])
      end
    end
  end
end
