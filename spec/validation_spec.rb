$:.unshift File.expand_path("../..", __FILE__)
require 'spec_helper'

describe ShEx::Algebra do
  before(:each) {$stderr = StringIO.new}
  after(:each) {$stderr = STDERR}
  let(:logger) {RDF::Spec.logger}

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
        schema: %(PREFIX ex: <http://schema.example/> ex:IssueShape {ex:submittedBy /genUser[0-9]+/i}),
        data: %(
          <issue6> ex:submittedBy _:genuser218 .
          <issue7> ex:submittedBy _:gencontact817 .
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
          {focus: "issue8", shape: "http://schema.example/EmployeeShape", result: ShEx::NotSatisfied},
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
          {focus: "http://a.example/Alice", shape: "http://schema.example/UserShape", result: ShEx::NotSatisfied},
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
          {result: true},
        ],
        map: {
          "http://inst.example/Issue1" => "http://schema.example/IssueShape",
          "http://inst.example/Tester2" => "http://schema.example/TesterShape"
        }
      },
      "Recursion Example" => {
        schema: %(PREFIX ex: <http://schema.example/> ex:IssueShape {ex:related @ex:IssueShape*}),
        data: %(
          PREFIX ex: <http://schema.example/>
          PREFIX inst: <http://inst.example/>
          inst:Issue1 ex:related inst:Issue2 .
          inst:Issue2 ex:related inst:Issue3 .
          inst:Issue3 ex:related inst:Issue1 .
        ),
        expected: [
          {result: true},
        ],
        map: {
          "http://inst.example/Issue1" => "http://schema.example/IssueShape",
          "http://inst.example/Issue2" => "http://schema.example/IssueShape",
          "http://inst.example/Issue3" => "http://schema.example/IssueShape"
        }
      },
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
          {result: true},
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
          PREFIX ex: <http://schema.example/>
          PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
          PREFIX foaf: <http://xmlns.com/foaf/0.1/>
        )}
        let(:graph) {RDF::Graph.new {|g| RDF::Turtle::Reader.new(decls + params[:data]) {|r| g << r}}}
        params[:expected].each_with_index do |p, ndx|
          it "#{p[:focus] || params[:map].inspect} (#{p[:result].inspect})" do
            if graph.empty?
              fail "No triples in graph"
            else
              map = if !params[:map] && p[:focus] && p[:shape]
                {RDF::URI(p.delete(:focus)) => RDF::URI(p.delete(:shape))}
              else
                params[:map].inject({}) {|memo, (k,v)| memo.merge(RDF::URI(k) => Array(v).map {|vv| RDF::URI(vv)})}
              end
              expect(schema).to satisfy(graph, params[:data], map, focus: p[:focus], expected: p[:result], logger: logger)
            end
          end
        end
      end
    end
  end

  require 'suite_helper'
  SHEXR = File.expand_path("../shexTest/doc/ShExR.shex", __FILE__)
  manifest = Fixtures::SuiteTest::BASE + "validation/manifest.jsonld"
  Fixtures::SuiteTest::Manifest.open(manifest) do |m|
    describe m.attributes['rdfs:comment'] do
      m.entries.each do |t|
        specify "#{t.name} – #{t.comment}#{' (negative)' if t.negative_test?}" do
          case t.name
          when 'nPlus1', 'PTstar-greedy-fail'
            pending "greedy"
          when '1val1DECIMAL_00'
            pending "Turtle reader ensures numeric literals start with a sign or digit, not '.'."
          when 'float-1E0_fail', 'boolean-0_fail', 'boolean-1_fail'
            pending "difference of opinion on literal validitity"
          when '1datatypeRef1_fail-datatype', '1datatypeRef1_fail-reflexiveRef'
            pending "sync with litNodeType and shapeRef change"
          when '1literalPattern_with_all_punctuation_pass',
               '1literalPattern_with_all_punctuation_fail'
            pending "empty char-class"
          when '1literalPattern_with_REGEXP_escapes_escaped_pass',
               '1literalPattern_with_REGEXP_escapes_escaped_fail_escapes',
               '1literalPattern_with_REGEXP_escapes_escaped_fail_escapes_bare'
            skip "invalid multibyte character"
          end
          t.debug = [
            "info: #{t.inspect}",
            "schema: #{t.schema_source}",
            "data: #{t.data_source}",
            "shexc: #{SXP::Generator.string(ShEx.parse(t.schema_source).to_sxp_bin)}"
          ]
          expected = t.positive_test? || ShEx::NotSatisfied
          schema = ShEx.parse(t.schema_source, validate: true, base_uri: t.base)
          focus = ShEx::Algebra::Operator.value(t.focus, base_uri: t.base)
          map = if t.map
            t.shape_map.inject({}) do |memo, (k,v)|
              memo.merge(ShEx::Algebra::Operator.value(k, base_uri: t.base) => ShEx::Algebra::Operator.iri(v, base_uri: t.base))
            end
          elsif t.shape
            {focus => ShEx::Algebra::Operator.iri(t.shape, base_uri: t.base)}
          else
            {}
          end
          focus = nil unless map.empty?
          expect(schema).to satisfy(t.graph, t.data_source, map,
                                    focus: focus,
                                    expected: expected,
                                    results: t.results,
                                    logger: t.logger,
                                    base_uri: t.base,
                                    shapeExterns: t.shapeExterns)
        end

        specify "#{t.name} – #{t.comment}#{' (negative)' if t.negative_test?} (ShExJ)" do
          case t.name
          when 'nPlus1', 'PTstar-greedy-fail'
            pending "greedy"
          when '1val1DECIMAL_00'
            pending "Turtle reader ensures numeric literals start with a sign or digit, not '.'."
          when 'float-1E0_fail', 'boolean-0_fail', 'boolean-1_fail'
            pending "difference of opinion on literal validitity"
          when '1datatypeRef1_fail-datatype', '1datatypeRef1_fail-reflexiveRef'
            pending "sync with litNodeType and shapeRef change"
          when '1literalPattern_with_all_punctuation_pass',
               '1literalPattern_with_all_punctuation_fail'
            pending "empty char-class"
          when '1literalPattern_with_REGEXP_escapes_escaped_pass',
               '1literalPattern_with_REGEXP_escapes_escaped_fail_escapes',
               '1literalPattern_with_REGEXP_escapes_escaped_fail_escapes_bare'
            pending "invalid multibyte character"
          end
          t.debug = [
            "info: #{t.inspect}",
            "schema: #{t.schema_source}",
            "data: #{t.data_source}",
            "json: #{t.schema_json}",
            "shexc: #{SXP::Generator.string(ShEx.parse(t.schema_source).to_sxp_bin)}"
          ]
          expected = t.positive_test? || ShEx::NotSatisfied
          schema = ShEx.parse(t.schema_json, format: :shexj, validate: true, base_uri: t.base)
          t.debug << "shexc(2): #{SXP::Generator.string(schema.to_sxp_bin)}"
          focus = ShEx::Algebra::Operator.value(t.focus, base_uri: t.base)
          map = if t.map
            t.shape_map.inject({}) do |memo, (k,v)|
              memo.merge(ShEx::Algebra::Operator.value(k, base_uri: t.base) => ShEx::Algebra::Operator.iri(v, base_uri: t.base))
            end
          elsif t.shape
            {focus => ShEx::Algebra::Operator.iri(t.shape, base_uri: t.base)}
          else
            {}
          end
          focus = nil unless map.empty?
          expect(schema).to satisfy(t.graph, t.data_source, map,
                                    focus: focus,
                                    expected: expected,
                                    results: t.results,
                                    logger: t.logger,
                                    base_uri: t.base,
                                    shapeExterns: t.shapeExterns)
        end

        # Run with rspec --tag shexr
        # This tests the tests, not the implementation
        if File.exist?(SHEXR)
          let(:shexr) {@@shexr ||= ShEx.open(SHEXR)}
          specify "#{t.name} validates against ShExR.shex", shexr: true do
            graph = RDF::Graph.new {|g| g << JSON::LD::Reader.new(t.schema_json, base_uri: t.base)}
            focus = graph.first_subject(predicate: RDF.type, object: RDF::URI("http://www.w3.org/ns/shex#Schema"))
            expect(focus).to be_a(RDF::Resource)
            t.logger.level = Logger::DEBUG
            expect(shexr).to satisfy(graph, t.schema_json, {}, focus: focus, logger: t.logger)
          end
        end
      end
    end
  end
end
