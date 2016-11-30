$:.unshift File.expand_path("../..", __FILE__)
require 'spec_helper'

describe ShEx::Algebra, skip: "Not ready yet" do
  before(:each) {$stderr = StringIO.new}
  after(:each) {$stderr = STDERR}

  describe "satisfies" do
    {
      "Node Kind Example" => {
        shex: %(ex:IssueShape {ex:state IRI}),
        expected: [
          {ttl: %(<issue1> ex:state ex:HunkyDory .), result: true},
          {ttl: %(<issue2> ex:taste ex:GoodEnough .), result: false},
          {ttl: %(<issue2> ex:taste ex:GoodEnough .), result: false},
        ]
      },
    }.each do |label, params|
      context params[:shex] do
        params[:expected].each_with_index do |p, ndx|
          if p[:result]
            specify("pattern #{ndx}") {expect(p[:ttl]).to satisfy(params[:shex])}
          else
            specify("pattern #{ndx}") {expect(p[:ttl]).not_to satisfy(params[:shex])}
          end
        end
      end
    end
  end
end
