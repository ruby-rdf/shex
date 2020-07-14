# coding: utf-8
$:.unshift "."
require 'spec_helper'
require 'rdf/spec/format'

describe ShEx::Format do
  it_behaves_like 'an RDF::Format' do
    let(:format_class) {ShEx::Format}
  end

  describe ".for" do
    [
      :shex,
      "etc/doap.shex",
      {file_name:      'etc/doap.shex'},
      {file_extension: 'shex'},
      {content_type:   'application/shex'},
    ].each do |arg|
      it "discovers with #{arg.inspect}" do
        expect(RDF::Format.for(arg)).to eq described_class
      end
    end
  end

  describe "#to_sym" do
    specify {expect(described_class.to_sym).to eq :shex}
  end

  describe ".cli_commands" do
    require 'rdf/cli'
    let(:ttl) {File.expand_path("../../etc/doap.ttl", __FILE__)}
    let(:schema) {File.expand_path("../../etc/doap.shex", __FILE__)}
    let(:schema_input) {File.read(schema)} # Not encoded, since decode done in option parsing
    let(:focus) {"https://rubygems.org/gems/shex"}
    let(:messages) {Hash.new}

    describe "#shex" do
      it "matches from file" do
        expect {RDF::CLI.exec(["shex", ttl], focus: focus, schema: schema, messages: messages)}.not_to write.to(:output)
        expect(messages).not_to be_empty
      end
      it "patches from StringIO" do
        expect {RDF::CLI.exec(["shex", ttl], focus: focus, schema: StringIO.new(schema_input), messages: messages)}.not_to write.to(:output)
        expect(messages).not_to be_empty
      end
      it "patches from argument" do
        expect {RDF::CLI.exec(["shex", ttl], focus: focus, schema_input: schema_input, messages: messages)}.not_to write.to(:output)
        expect(messages).not_to be_empty
      end
    end
  end
end
