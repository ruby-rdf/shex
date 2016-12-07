$:.unshift File.expand_path("../..", __FILE__)
require 'spec_helper'

describe ShEx::Algebra do
  before(:each) {$stderr = StringIO.new}
  after(:each) {$stderr = STDERR}

  describe "#satisfies?" do
    {
      "Node Kind Example 1" => {
        schema: %(PREFIX ex: <http://schema.example/> ex:IssueShape {ex:state IRI}),
        data: %(
          <issue1> ex:state ex:HunkyDory .
          <issue2> ex:taste ex:GoodEnough .
          <issue3> ex:state "just fine" .
        ),
        expected: [
          {focus: "issue1", shape: "http://schema.example/IssueShape", result: true},
          {focus: "issue2", shape: "http://schema.example/IssueShape", result: ShEx::NotSatisfied},
          {focus: "issue3", shape: "http://schema.example/IssueShape", result: ShEx::NotSatisfied},
        ]
      },
      "Datatype Example 1" => {
        schema: %(
          PREFIX ex: <http://schema.example/>
          PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
          ex:IssueShape {ex:submittedOn xsd:date}
        ),
        data: %(
          <issue1> ex:submittedOn "2016-07-08"^^xsd:date .
          <issue2> ex:submittedOn "2016-07-08T01:23:45Z"^^xsd:dateTime .
        ),
        expected: [
          {focus: "issue1", shape: "http://schema.example/IssueShape", result: true},
          {focus: "issue2", shape: "http://schema.example/IssueShape", result: ShEx::NotSatisfied},
        ]
      },
      "String Facets Example 1" => {
        schema: %(
          PREFIX ex: <http://schema.example/>
          PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
          ex:IssueShape {ex:submittedBy MINLENGTH 10}),
        data: %(
          <issue1> ex:submittedBy <http://a.example/bob> . # 20 characters
          <issue2> ex:submittedBy "Bob" . # 3 characters
        ),
        expected: [
          {focus: "issue1", shape: "http://schema.example/IssueShape", result: true},
          {focus: "issue2", shape: "http://schema.example/IssueShape", result: ShEx::NotSatisfied},
        ]
      },
      "String Facets Example 2" => {
        schema: %(PREFIX ex: <http://schema.example/> ex:IssueShape {ex:submittedBy PATTERN "genUser[0-9]+"}),
        data: %(
          <issue6> ex:submittedBy _:genUser218 .
          <issue7> ex:submittedBy _:genContact817 .
        ),
        expected: [
          {focus: "issue6", shape: "http://schema.example/IssueShape", result: true},
          {focus: "issue7", shape: "http://schema.example/IssueShape", result: ShEx::NotSatisfied},
        ]
      },
      "Numeric Facets Example 1" => {
        schema: %(PREFIX ex: <http://schema.example/> ex:IssueShape {ex:confirmations MININCLUSIVE 1}),
        data: %(
          <issue1> ex:confirmations 1 .
          <issue2> ex:confirmations 0 .
          <issue3> ex:confirmations "ii"^^ex:romanNumeral .
        ),
        expected: [
          {focus: "issue1", shape: "http://schema.example/IssueShape", result: true},
          {focus: "issue2", shape: "http://schema.example/IssueShape", result: ShEx::NotSatisfied},
          {focus: "issue3", shape: "http://schema.example/IssueShape", result: ShEx::NotSatisfied},
        ]
      },
      "Values Constraint Example 1" => {
        schema: %(PREFIX ex: <http://schema.example/> ex:NoActionIssueShape {ex:state [ ex:Resolved ex:Rejected ]}),
        data: %(
          <issue1> ex:state ex:Resolved .
          <issue2> ex:state ex:Unresolved .
        ),
        expected: [
          {focus: "issue1", shape: "http://schema.example/NoActionIssueShape", result: true},
          {focus: "issue2", shape: "http://schema.example/NoActionIssueShape", result: ShEx::NotSatisfied},
        ]
      },
      "Values Constraint Example 2" => {
        schema: %(
          PREFIX ex: <http://schema.example/>
          PREFIX foaf: <http://xmlns.com/foaf/0.1/>
          ex:EmployeeShape {
              foaf:mbox [ "N/A"
                          <mailto:engineering->~
                          <mailto:sales->~
                              - <mailto:sales-contacts>~
                              - <mailto:sales-interns>~ ]
            }
        ),
        data: %(
          <issue3> foaf:mbox "N/A" .
          <issue4> foaf:mbox <mailto:engineering-2112@a.example> .
          <issue5> foaf:mbox <mailto:sales-835@a.example> .
          <issue6> foaf:mbox "missing" .
          <issue7> foaf:mbox <mailto:sales-contacts-999@a.example> .
        ),
        expected: [
          {focus: "issue3", shape: "http://schema.example/EmployeeShape", result: true},
          {focus: "issue4", shape: "http://schema.example/EmployeeShape", result: true},
          {focus: "issue5", shape: "http://schema.example/EmployeeShape", result: true},
          {focus: "issue6", shape: "http://schema.example/EmployeeShape", result: ShEx::NotSatisfied},
          {focus: "issue7", shape: "http://schema.example/EmployeeShape", result: ShEx::NotSatisfied},
        ]
      },
      "Values Constraint Example 3" => {
        schema: %(
          PREFIX ex: <http://schema.example/>
          PREFIX foaf: <http://xmlns.com/foaf/0.1/>
          ex:EmployeeShape {
              foaf:mbox [ . - <mailto:engineering->~ - <mailto:sales->~ ]
            }
        ),
        data: %(
          <issue8> foaf:mbox 123 .
          <issue9> foaf:mbox <mailto:core-engineering-2112@a.example> .
          <issue10> foaf:mbox <mailto:engineering-2112@a.example> .
        ),
        expected: [
          {focus: "issue8", shape: "http://schema.example/EmployeeShape", result: true},
          {focus: "issue9", shape: "http://schema.example/EmployeeShape", result: true},
          {focus: "issue10", shape: "http://schema.example/EmployeeShape", result: ShEx::NotSatisfied},
        ]
      },
      "Semantic Actions Example 1" => {
        schema: %(
          PREFIX ex: <http://schema.example/>
          PREFIX Test: <http://shex.io/extensions/Test/>
          ex:S1 {
            ex:p1 .+ %Test:{ print(s) %} %Test:{ print(o) %}
          }
        ),
        data: %(
          <http://a.example/n1> ex:p1 <http://a.example/o1> .
          <http://a.example/n2> ex:p1 "a", "b" .
          <http://a.example/n3> ex:p2 <http://a.example/o2> .
        ),
        expected: [
          {focus: "http://a.example/n1", shape: "http://schema.example/S1", result: true},
          {focus: "http://a.example/n2", shape: "http://schema.example/S1", result: true},
          {focus: "http://a.example/n3", shape: "http://schema.example/S1", result: ShEx::NotSatisfied},
        ]
      },
      "Validation Example 1" => {
        schema: %(
          PREFIX ex: <http://schema.example/>
          PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
          ex:IntConstraint {ex:p xsd:integer}
        ),
        data: %(
          <http://a.example/s> ex:p 30 .
        ),
        expected: [
          {focus: "http://a.example/s", shape: "http://schema.example/IntConstraint", result: true},
        ]
      },
      "Validation Example 2" => {
        schema: %(PREFIX ex: <http://schema.example/> ex:UserShape {ex:shoeSize .}),
        data: %(
          BASE <http://a.example/>
          PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
          <Alice> ex:shoeSize "30"^^xsd:integer .
        ),
        expected: [
          {focus: "http://a.example/Alice", shape: "http://schema.example/UserShape", result: true},
        ]
      },
      "Validation Example 3" => {
        schema: %(PREFIX ex: <http://schema.example/> ex:UserShape EXTRA a {a [ex:Teacher]}),
        data: %(
          BASE <http://a.example/>
          PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
          <Alice> ex:shoeSize "30"^^xsd:integer .
          <Alice> a ex:Teacher .
          <Alice> a ex:Person .
          <SomeHat> ex:owner <Alice> .
          <TheMoon> ex:madeOf <GreenCheese> .
        ),
        expected: [
          {focus: "http://a.example/Alice", shape: "http://schema.example/UserShape", result: true},
        ]
      },
      "Disjunction Example 1" => {
        schema: %(
          PREFIX ex: <http://schema.example/>
          PREFIX foaf: <http://xmlns.com/foaf/0.1/>
          ex:UserShape {
           (              # extra ()s to clarify alignment with ShExJ
            foaf:name LITERAL |
            (             # extra ()s to clarify alignment with ShExJ
             foaf:givenName LITERAL+ ;
             foaf:familyName LITERAL
            )
           )
          }
        ),
        data: %(
          BASE <http://a.example/>
          PREFIX foaf: <http://xmlns.com/foaf/0.1/>
          <Alice> foaf:givenName "Alice" .
          <Alice> foaf:givenName "Malsenior" .
          <Alice> foaf:familyName "Walker" .
          <Alice> foaf:mbox <mailto:alice@example.com> .
          <Bob> foaf:knows <Alice> .
          <Bob> foaf:mbox <mailto:bob@example.com> .
        ),
        expected: [
          {focus: "http://a.example/Alice", shape: "http://schema.example/UserShape", result: true},
        ]
      },
      "Disjunction Example 2" => {
        schema: %(
          PREFIX ex: <http://schema.example/>
          PREFIX foaf: <http://xmlns.com/foaf/0.1/>
          ex:UserShape {
           (              # extra ()s to clarify alignment with ShExJ
            foaf:name LITERAL |
            (             # extra ()s to clarify alignment with ShExJ
             foaf:givenName LITERAL+ ;
             foaf:familyName LITERAL
            )
           )
          }
        ),
        data: %(
          BASE <http://a.example/>
          PREFIX foaf: <http://xmlns.com/foaf/0.1/>
          <Alice> foaf:mbox <mailto:alice@example.com> .
          <Bob> foaf:knows <Alice> .
          <Bob> foaf:mbox <mailto:bob@example.com> .
          <Alice> foaf:name "Alice Malsenior Walker" .
        ),
        expected: [
          {focus: "http://a.example/Alice", shape: "http://schema.example/UserShape", result: true},
        ]
      },
      "Disjunction Example 3" => {
        schema: %(
          PREFIX ex: <http://schema.example/>
          PREFIX foaf: <http://xmlns.com/foaf/0.1/>
          ex:UserShape {
           (              # extra ()s to clarify alignment with ShExJ
            foaf:name LITERAL |
            (             # extra ()s to clarify alignment with ShExJ
             foaf:givenName LITERAL+ ;
             foaf:familyName LITERAL
            )
           )
          }
        ),
        data: %(
          BASE <http://a.example/>
          PREFIX foaf: <http://xmlns.com/foaf/0.1/>
          <Alice> foaf:familyName "Walker" .
          <Alice> foaf:mbox <mailto:alice@example.com> .
          <Bob> foaf:knows <Alice> .
          <Bob> foaf:mbox <mailto:bob@example.com> .
          <Alice> foaf:name "Alice Malsenior Walker" .
        ),
        expected: [
          {focus: "http://a.example/Alice", shape: "http://schema.example/UserShape", result: ShEx::NotSatisfied},
        ]
      },
      "Disjunction Example 4" => {
        schema: %(
          PREFIX ex: <http://schema.example/>
          PREFIX foaf: <http://xmlns.com/foaf/0.1/>
          ex:UserShape extra foaf:familyName {
           (              # extra ()s to clarify alignment with ShExJ
            foaf:name LITERAL |
            (             # extra ()s to clarify alignment with ShExJ
             foaf:givenName LITERAL+ ;
             foaf:familyName LITERAL
            )
           )
          }
        ),
        data: %(
          BASE <http://a.example/>
          PREFIX foaf: <http://xmlns.com/foaf/0.1/>
          <Alice> foaf:familyName "Walker" .
          <Alice> foaf:mbox <mailto:alice@example.com> .
          <Bob> foaf:knows <Alice> .
          <Bob> foaf:mbox <mailto:bob@example.com> .
          <Alice> foaf:name "Alice Malsenior Walker" .
        ),
        expected: [
          {focus: "http://a.example/Alice", shape: "http://schema.example/UserShape", result: true},
        ]
      },
      "Disjunction Example 5" => {
        schema: %(
          PREFIX ex: <http://schema.example/>
          PREFIX foaf: <http://xmlns.com/foaf/0.1/>
          ex:UserShape closed extra foaf:familyName {
           (              # extra ()s to clarify alignment with ShExJ
            foaf:name LITERAL |
            (             # extra ()s to clarify alignment with ShExJ
             foaf:givenName LITERAL+ ;
             foaf:familyName LITERAL
            )
           )
          }
        ),
        data: %(
          BASE <http://a.example/>
          PREFIX foaf: <http://xmlns.com/foaf/0.1/>
          <Alice> foaf:familyName "Walker" .
          <Alice> foaf:mbox <mailto:alice@example.com> .
          <Bob> foaf:knows <Alice> .
          <Bob> foaf:mbox <mailto:bob@example.com> .
          <Alice> foaf:name "Alice Malsenior Walker" .
        ),
        expected: [
          {focus: "http://a.example/Alice", shape: "http://schema.example/UserShape", result: ShEx::NotSatisfied},
        ]
      },
      "Dependent Shape Example" => {
        schema: %(
          PREFIX ex: <http://schema.example/>
          ex:IssueShape {
            ex:reproducedBy @ex:TesterShape
          }
          ex:TesterShape {
            ex:role [ex:testingRole]
          }
        ),
        data: %(
          PREFIX ex: <http://schema.example/>
          PREFIX inst: <http://inst.example/>
          inst:Issue1 ex:reproducedBy inst:Tester2 .
          inst:Tester2 ex:role ex:testingRole .
        ),
        expected: [
          {focus: "http://inst.example/Issue1", shape: "http://schema.example/IssueShape", result: true},
        ],
        map: {
          "http://inst.example/Issue1" => "http://schema.example/IssueShape",
          "http://inst.example/Tester2" => "http://schema.example/TesterShape",
          "http://inst.example/Testgrammer23" => "http://schema.example/ProgrammerShape"
        }
      },
      # FIXME
      #"Recursion Example" => {
      #  schema: %(PREFIX ex: <http://schema.example/> ex:IssueShape {ex:related @ex:IssueShape*}),
      #  data: %(
      #    PREFIX ex: <http://schema.example/>
      #    PREFIX inst: <http://inst.example/>
      #    inst:Issue1 ex:related inst:Issue2 .
      #    inst:Issue2 ex:related inst:Issue3 .
      #    inst:Issue3 ex:related inst:Issue1 .
      #  ),
      #  expected: [
      #    {focus: "http://inst.example/Issue1", shape: "http://schema.example/IssueShape", result: true},
      #  ],
      #  map: {
      #    "http://inst.example/Issue1" => "http://schema.example/IssueShape",
      #    "http://inst.example/Issue2" => "http://schema.example/IssueShape",
      #    "http://inst.example/Issue3" => "http://schema.example/IssueShape"
      #  }
      #},
      "Simple Repeated Property Examples" => {
        schema: %(
          PREFIX ex: <http://schema.example/>
          ex:TestResultsShape {
            ex:val ["a" "b" "c"]+;
            ex:val ["b" "c" "d"]+
          }
        ),
        data: %(
          BASE <http://a.example/>
          PREFIX ex: <http://schema.example/>
          <s> ex:val "a" .
          <s> ex:val "b" .
          <s> ex:val "c" .
          <s> ex:val "d" .
        ),
        expected: [
          {focus: "http://a.example/s", shape: "http://schema.example/TestResultsShape", result: true},
        ]
      },
      "Repeated Property With Dependent Shapes Example" => {
        schema: %(
          PREFIX ex: <http://schema.example/>
          ex:IssueShape {
            ex:reproducedBy @ex:TesterShape;
            ex:reproducedBy @ex:ProgrammerShape
          }
          ex:TesterShape {
            ex:role [ex:testingRole]
          }
          ex:ProgrammerShape {
            ex:department [ex:ProgrammingDepartment]
          }
        ),
        data: %(
          PREFIX ex: <http://schema.example/>
          PREFIX inst: <http://inst.example/>
          inst:Issue1
            ex:reproducedBy inst:Tester2 ;
            ex:reproducedBy inst:Testgrammer23 .

          inst:Tester2              
            ex:role ex:testingRole .

          inst:Testgrammer23                        
            ex:role ex:testingRole ;                
            ex:department ex:ProgrammingDepartment .
        ),
        expected: [
          {focus: "http://inst.example/Issue1", shape: "http://schema.example/IssueShape", result: true},
        ],
        map: {
          "http://inst.example/Issue1" => "http://schema.example/IssueShape",
          "http://inst.example/Tester2" => "http://schema.example/TesterShape",
          "http://inst.example/Testgrammer23" => "http://schema.example/ProgrammerShape"
        }
      },
    }.each do |label, params|
      context label do
        let(:schema) {ShEx.parse(params[:schema])}
        let(:decls) {%(
          BASE <http://example.com/>
          PREFIX ex: <http://schema.example/>
          PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
          PREFIX foaf: <http://xmlns.com/foaf/0.1/>
        )}
        let(:graph) {RDF::Graph.new {|g| RDF::Turtle::Reader.new(decls + params[:data]) {|r| g << r}}}
        params[:expected].each_with_index do |p, ndx|
          it "#{p[:focus]}" do
            if graph.empty?
              fail "No triples in graph"
            else
              expect(schema).to satisfy(graph, params[:data], p[:focus], p[:shape], params[:map], p[:result])
            end
          end
        end
      end
    end
  end

  require 'suite_helper'
  manifest = Fixtures::SuiteTest::BASE + "/validation/manifest.jsonld"
  Fixtures::SuiteTest::Manifest.open(manifest) do |m|
    describe m.attributes['rdfs:comment'], skip: "In progress" do
      m.entries.each do |t|
        specify "#{t.name}–#{t.comment}#{'( negative)' if t.negative_test?}" do
          schema = ShEx.parse(t.schema_source)
          expect(schema).to satisfy(t.graph, File.read(t.data), t.focus, t.shape, nil, t.positive_test? || ShEx::NotSatisfied)
        end
      end
    end
  end
end
