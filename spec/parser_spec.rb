$:.unshift File.expand_path("../..", __FILE__)
require 'spec_helper'

describe ShEx do
  describe ".parse" do
    specify do
      input = %(<http://a.example/S1> {})
      expect(described_class.parse(input)).to be_a(ShEx::Algebra::Schema)
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
    it "renders an empty schema" do
      expect("").to generate("(schema)")
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
        sxp: %{(schema (shape <http://a.example/S1>))}
      },
    }.each do |name, params|
      it name do
        expect(params[:shexc]).to generate(params[:sxp])
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
        expect(params[:input]).to generate(params[:result], validate: true)
      end
    end
  end

  context "schema to SSE" do
    context "Positive Syntax Tests" do
      Dir.glob("spec/shexTest/schemas/*.shex").
        map {|f| f.split('/').last.sub('.shex', '')}.
        each do |file|
        it file do
          input = File.read File.expand_path("../shexTest/schemas/#{file}.shex", __FILE__)

          case file
          when '_all'
            pending("All has a self-including shape, which is invalid")
          end
        
          sse = File.read(File.expand_path("../data/#{file}.sse", __FILE__))
          expect(input).to generate(sse, validate: true)
        end
      end
    end

    context "Negative Syntax Tests" do
      Dir.glob("spec/shexTest/negativeSyntax/*.shex").
        map {|f| f.split('/').last.sub('.shex', '')}.
        each do |file|
        it file do
          input = File.read File.expand_path("../shexTest/negativeSyntax/#{file}.shex", __FILE__)

          case file
          when 'openopen1dotOr1dotclose'
            pending("Missing production multiElementSomeOf")
          end
          expect(input).to generate(ShEx::ParseError, validate: true)
        end
      end
    end

    context "Negative Structure Tests" do
      Dir.glob("spec/shexTest/negativeStructure/*.shex").
        map {|f| f.split('/').last.sub('.shex', '')}.
        each do |file|
        it file do
          input = File.read File.expand_path("../shexTest/negativeStructure/#{file}.shex", __FILE__)

          case file
          when '1focusRefANDSelfdot'
            pending("It is self referning (OK?) and includes an empty shape (OK?)")
          end
          expect(input).to generate(ShEx::ParseError, validate: true)
        end
      end
    end
  end
end
