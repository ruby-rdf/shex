$:.unshift File.expand_path("../..", __FILE__)
require 'spec_helper'

describe ShEx::Extension do
  describe ".each" do
    it "inumerates pre-defined extensions" do
      expect {|b| ShEx::Extension.each(&b)}.to yield_control.at_least(1).times
      expect(ShEx::Extension.each.to_a).to include(ShEx::Test)
    end
  end

  describe ".find" do
    it "finds Test" do
      expect(ShEx::Extension.find("http://shex.io/extensions/Test/")).to eq ShEx::Test
    end
  end
end

describe ShEx::Test do
  specify do
    expect(ShEx::Test.name).to eq "http://shex.io/extensions/Test/"
  end
end
