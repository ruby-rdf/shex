$:.unshift File.expand_path("../..", __FILE__)
require 'spec_helper'

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
          "@context": "https://shexspec.github.io/context.jsonld",
          "type": "Schema",
          "shapes": [
            {
              "label": "http://a.example/S1",
              "type": "Shape"
            }
          ]
        }),
        sxp: %{(schema (shapes (shape (label <http://a.example/S1>))))}
      },
      "Node Kind Example 1" => {
        shexc: %(PREFIX ex: <http://schema.example/> ex:IssueShape {ex:state IRI}),
        shexj: %({
          "@context": "https://shexspec.github.io/context.jsonld",
          "type": "Schema",
          "shapes": [
            {
              "type": "Shape",
              "label": "http://schema.example/IssueShape",
              "expression": {
                "type": "TripleConstraint",
                "predicate": "http://schema.example/state",
                "valueExpr": {
                  "type": "NodeConstraint", "nodeKind": "iri"
                }
              }
            }
          ]
        }),
        sxp: %{(schema
         (shapes
           (shape
             (label <http://schema.example/IssueShape>)
             (tripleConstraint <http://schema.example/state> (nodeConstraint iri)))))}
      },
      "Datatype Example 1" => {
        shexc: %(
          PREFIX ex: <http://schema.example/>
          PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
          ex:IssueShape {ex:submittedOn xsd:dateTime}
        ),
        shexj: %({
          "@context": "https://shexspec.github.io/context.jsonld",
          "type": "Schema",
          "shapes": [
            {
              "type": "Shape",
              "label": "http://schema.example/IssueShape",
              "expression": {
                "type": "TripleConstraint",
                "predicate": "http://schema.example/submittedOn",
                "valueExpr": {
                  "type": "NodeConstraint",
                  "datatype": "http://www.w3.org/2001/XMLSchema#dateTime"
                }
              }
            }
          ]
        }),
        sxp: %{(schema
         (shapes (shape
          (label <http://schema.example/IssueShape>)
          (tripleConstraint <http://schema.example/submittedOn>
           (nodeConstraint (datatype <http://www.w3.org/2001/XMLSchema#dateTime>))))))}
      },
      "String Facets Example 1" => {
        shexc: %(
          PREFIX ex: <http://schema.example/>
          PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
          ex:IssueShape {ex:submittedBy MINLENGTH 10}),
        shexj: %({
          "@context": "https://shexspec.github.io/context.jsonld",
          "type": "Schema",
          "shapes": [
            {
              "type": "Shape",
              "label": "http://schema.example/IssueShape",
              "expression": {
                "type": "TripleConstraint",
                "predicate": "http://schema.example/submittedBy",
                "valueExpr": { "type": "NodeConstraint", "minlength": 10 }
              }
            }
          ]
        }),
        sxp: %{(schema
         (shapes
          (shape
           (label <http://schema.example/IssueShape>)
           (tripleConstraint <http://schema.example/submittedBy> (nodeConstraint (minlength 10))))))}
      },
      "String Facets Example 2" => {
        shexc: %(PREFIX ex: <http://schema.example/> ex:IssueShape {ex:submittedBy PATTERN "genUser[0-9]+"}),
        shexj: %({
          "@context": "https://shexspec.github.io/context.jsonld",
          "type": "Schema",
          "shapes": [
            {
              "type": "Shape",
              "label": "http://schema.example/IssueShape",
              "expression": {
                "type": "TripleConstraint",
                "predicate": "http://schema.example/submittedBy",
                "valueExpr": {
                  "type": "NodeConstraint",
                  "pattern": "genUser[0-9]+"
                }
              }
            }
          ]
        }),
        sxp: %{(schema
         (shapes
          (shape
           (label <http://schema.example/IssueShape>)
           (tripleConstraint <http://schema.example/submittedBy>
            (nodeConstraint (pattern "genUser[0-9]+"))))))}
      },
      "Numeric Facets Example 1" => {
        shexc: %(PREFIX ex: <http://schema.example/> ex:IssueShape {ex:confirmations MININCLUSIVE 1}),
        shexj: %({
          "@context": "https://shexspec.github.io/context.jsonld",
          "type": "Schema",
          "shapes": [
            {
              "type": "Shape",
              "label": "http://schema.example/IssueShape",
              "expression": {
                "type": "TripleConstraint",
                "predicate": "http://schema.example/confirmations",
                "valueExpr": { "type": "NodeConstraint", "mininclusive": 1 }
              }
            }
          ]
        }),
        sxp: %{(schema
         (shapes
          (shape
           (label <http://schema.example/IssueShape>)
           (tripleConstraint <http://schema.example/confirmations>
            (nodeConstraint (mininclusive 1))))))}
      },
      "Values Constraint Example 1" => {
        shexc: %(PREFIX ex: <http://schema.example/> ex:NoActionIssueShape {ex:state [ ex:Resolved ex:Rejected ]}),
        shexj: %({
          "@context": "https://shexspec.github.io/context.jsonld",
          "type": "Schema",
          "shapes": [
            {
              "type": "Shape",
              "label": "http://schema.example/NoActionIssueShape",
              "expression": {
                "type": "TripleConstraint",
                "predicate": "http://schema.example/state",
                "valueExpr": {
                  "type": "NodeConstraint",
                  "values": [
                    {"uri": "http://schema.example/Resolved"},
                    {"uri": "http://schema.example/Rejected"}
                  ]
                }
              }
            }
          ]
        }),
        sxp: %{(schema
         (shapes
          (shape
           (label <http://schema.example/NoActionIssueShape>)
            (tripleConstraint <http://schema.example/state>
             (nodeConstraint
              (value <http://schema.example/Resolved>)
              (value <http://schema.example/Rejected>))))))}
      },
      "Values Constraint Example 2" => {
        shexc: %(
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
        shexj: %({
          "@context": "https://shexspec.github.io/context.jsonld",
          "type": "Schema",
          "shapes": [
            {
              "type": "Shape",
              "label": "http://schema.example/EmployeeShape",
              "expression": {
                "type": "TripleConstraint",
                "predicate": "http://xmlns.com/foaf/0.1/mbox",
                "valueExpr": {
                  "type": "NodeConstraint",
                  "values": [
                    {"value": "N/A"},
                    { "type": "StemRange", "stem": "mailto:engineering-" },
                    { "type": "StemRange", "stem": "mailto:sales-",
                      "exclusions": [
                        { "type": "Stem", "stem": "mailto:sales-contacts" },
                        { "type": "Stem", "stem": "mailto:sales-interns" }
                      ]
                    }
                  ]
                }
              }
            }
          ]
        }),
        sxp: %{(schema
         (shapes
          (shape
           (label <http://schema.example/EmployeeShape>)
           (tripleConstraint <http://xmlns.com/foaf/0.1/mbox>
            (nodeConstraint
             (value "N/A")
             (value (stem <mailto:engineering->))
             (value
              (stemRange <mailto:sales->
               (exclusions (stem <mailto:sales-contacts>) (stem <mailto:sales-interns>))) )) )) ))}
      },
      "Values Constraint Example 3" => {
        shexc: %(
          PREFIX ex: <http://schema.example/>
          PREFIX foaf: <http://xmlns.com/foaf/0.1/>
          ex:EmployeeShape {
              foaf:mbox [ . - <mailto:engineering->~ - <mailto:sales->~ ]
            }
        ),
        shexj: %({
          "@context": "https://shexspec.github.io/context.jsonld",
          "type": "Schema",
          "shapes": [
            {
              "type": "Shape",
              "label": "http://schema.example/EmployeeShape",
              "expression": {
                "type": "TripleConstraint",
                "predicate": "http://xmlns.com/foaf/0.1/mbox",
                "valueExpr": {
                  "type": "NodeConstraint",
                  "values": [
                    { "type": "StemRange",
                      "stem": {"type": "Wildcard"},
                      "exclusions": [
                        { "type": "Stem", "stem": "mailto:engineering-" },
                        { "type": "Stem", "stem": "mailto:sales-" }
                      ]
                    }
                  ]
                }
              }
            }
          ]
        }),
        sxp: %{(schema
         (shapes
          (shape
           (label <http://schema.example/EmployeeShape>)
           (tripleConstraint <http://xmlns.com/foaf/0.1/mbox>
            (nodeConstraint
             (value
              (stemRange wildcard (exclusions (stem <mailto:engineering->) (stem <mailto:sales->)))) )))))}
      },
      "Inclusion Example" => {
        shexc: %(
          PREFIX ex: <http://schema.example/>
          PREFIX foaf: <http://xmlns.com/foaf/0.1/>
          ex:PersonShape {
            foaf:name .
          }
          ex:EmployeeShape {
            &ex:PersonShape ;
            ex:employeeNumber .
          }
        ),
        shexj: %({
          "@context": "https://shexspec.github.io/context.jsonld",
          "type":"Schema",
          "shapes": [
            {
              "type":"Shape",
              "label": "http://schema.example/PersonShape",
              "expression": {
                "type": "TripleConstraint",
                "predicate": "http://xmlns.com/foaf/0.1/name"
              }
            },
            {
              "type":"Shape",
              "label": "http://schema.example/EmployeeShape",
              "expression": {
                "type":"EachOf",
                "expressions": [
                  { "type": "Inclusion", "include": "http://schema.example/PersonShape" },
                  { "type": "TripleConstraint",
                    "predicate": "http://schema.example/employeeNumber"
                  }
                ]
              }
            }
          ]
        }),
        sxp: %{(schema
         (shapes
          (shape
           (label <http://schema.example/PersonShape>)
           (tripleConstraint <http://xmlns.com/foaf/0.1/name>))
          (shape
           (label <http://schema.example/EmployeeShape>)
           (eachOf
            (inclusion <http://schema.example/PersonShape>)
            (tripleConstraint <http://schema.example/employeeNumber>)) )) )}
      },
      "Double Negated reference" => {
        shexc: %(PREFIX ex: <http://schema.example/#> ex:S NOT (IRI OR NOT @ex:S)),
        shexj: %({
          "@context": "https://shexspec.github.io/context.jsonld",
          "type": "Schema",
          "shapes": [
            {
              "type": "ShapeNot",
              "label": "http://schema.example/#S",
              "shapeExpr": {
                "type": "ShapeOr",
                "shapeExprs": [
                  { "type": "NodeConstraint", "nodeKind": "iri" },
                  { "type": "ShapeNot",
                    "shapeExpr": {
                      "type": "ShapeRef",
                      "reference": "http://schema.example/#S"
                    }
                  }
                ]
              }
            }
          ]
        }),
        sxp: %{(schema
         (shapes
          (not
           (label <http://schema.example/#S>)
           (or
            (nodeConstraint iri)
            (not (shapeRef <http://schema.example/#S>))))) )}
      },
      "Semantic Actions Example 1" => {
        shexc: %(
          PREFIX ex: <http://a.example/>
          PREFIX Test: <http://shex.io/extensions/Test/>
          ex:S1 {
            ex:p1 . %Test:{ print(s) %} %Test:{ print(o) %}
          }
        ),
        shexj: %({
          "@context": "https://shexspec.github.io/context.jsonld",
          "type": "Schema",
          "shapes": [
            {
              "type": "Shape",
              "label": "http://a.example/S1",
              "expression": {
                "type": "TripleConstraint",
                "predicate": "http://a.example/p1",
                "semActs": [
                  { "type": "SemAct", "code": " print(s) ",
                    "name": "http://shex.io/extensions/Test/" },
                  { "type": "SemAct", "code": " print(o) ",
                    "name": "http://shex.io/extensions/Test/" }
                ]
              }
            }
          ]
        }),
        sxp: %{(schema
         (shapes
          (shape
           (label <http://a.example/S1>)
           (tripleConstraint <http://a.example/p1>
            (semact <http://shex.io/extensions/Test/> " print(s) ")
            (semact <http://shex.io/extensions/Test/> " print(o) ")) )) )}
      },
      "Annotations Example 1" => {
        shexc: %(
          PREFIX ex: <http://schema.example/>
          PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
          ex:IssueShape {
            ex:status .
                // rdfs:comment "Represents reported software issues."
                // rdfs:label "software issue"
          }
        ),
        shexj: %({
          "@context": "https://shexspec.github.io/context.jsonld",
          "type": "Schema",
          "shapes": [
            {
              "type": "Shape",
              "label": "http://schema.example/IssueShape",
              "expression": {
                "type": "TripleConstraint",
                "predicate": "http://schema.example/status",
                "annotations": [
                   { "type": "Annotation",
                     "predicate": "http://www.w3.org/2000/01/rdf-schema#comment",
                     "object": {"value": "Represents reported software issues."} },
                   { "type": "Annotation",
                     "predicate": "http://www.w3.org/2000/01/rdf-schema#label",
                     "object": {"value": "software issue"} } 
                ]
              }
            }
          ]
        }),
        sxp: %{(schema
         (shapes
          (shape
           (label <http://schema.example/IssueShape>)
           (tripleConstraint <http://schema.example/status>
            (annotation <http://www.w3.org/2000/01/rdf-schema#comment>
             "Represents reported software issues." )
            (annotation <http://www.w3.org/2000/01/rdf-schema#label> "software issue")))))}
      },
      "Validation Example 1" => {
        shexc: %(
          PREFIX ex: <http://schema.example/>
          PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
          ex:IntConstraint xsd:integer
        ),
        shexj: %({
          "@context": "https://shexspec.github.io/context.jsonld",
          "type": "Schema",
          "shapes": [
            {
              "type": "NodeConstraint",
              "label": "http://schema.example/IntConstraint",
              "datatype": "http://www.w3.org/2001/XMLSchema#integer"
            }
          ]
        }),
        sxp: %{(schema
         (shapes
          (nodeConstraint
           (label <http://schema.example/IntConstraint>)
           (datatype <http://www.w3.org/2001/XMLSchema#integer>)))
        )}
      },
      "Validation Example 2" => {
        shexc: %(PREFIX ex: <http://schema.example/> ex:UserShape {ex:shoeSize .}),
        shexj: %({
          "@context": "https://shexspec.github.io/context.jsonld",
          "type": "Schema",
          "shapes": [
            {
              "type": "Shape",
              "label": "http://schema.example/UserShape",
              "expression": {
                "type": "TripleConstraint",
                "predicate": "http://schema.example/shoeSize"
              }
            }
          ]
        }),
        sxp: %{(schema
         (shapes
          (shape
           (label <http://schema.example/UserShape>)
           (tripleConstraint <http://schema.example/shoeSize>))))}
      },
      "Validation Example 3" => {
        shexc: %(
          PREFIX ex: <http://schema.example/>
          ex:UserShape EXTRA a {a [ex:Teacher]}
        ),
        shexj: %({
          "@context": "https://shexspec.github.io/context.jsonld",
          "type": "Schema",
          "shapes": [
            {
              "type": "Shape",
              "label": "http://schema.example/UserShape",
              "extra": ["http://www.w3.org/1999/02/22-rdf-syntax-ns#type"],
              "expression": {
                "type": "TripleConstraint",
                "predicate": "http://www.w3.org/1999/02/22-rdf-syntax-ns#type",
                "valueExpr": {
                  "type": "NodeConstraint",
                  "values": [{"uri": "http://schema.example/Teacher"}]
                }
              }
            }
          ]
        }),
        sxp: %{(schema
         (shapes
           (shape
            (label <http://schema.example/UserShape>)
            (extra a)
            (tripleConstraint a (nodeConstraint (value <http://schema.example/Teacher>)))) ))}
      },
      "Disjunction Example" => {
        shexc: %(
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
        shexj: %({
          "@context": "https://shexspec.github.io/context.jsonld",
          "type": "Schema",
          "shapes": [
            {
              "type": "Shape",
              "label": "http://schema.example/UserShape",
              "expression": {
                "type": "OneOf",
                "expressions": [
                  { "type": "TripleConstraint",
                    "predicate": "http://xmlns.com/foaf/0.1/name",
                    "valueExpr":
                      { "type": "NodeConstraint", "nodeKind": "literal" } },
                  { "type": "EachOf",
                    "expressions": [
                      { "type": "TripleConstraint",
                        "predicate": "http://xmlns.com/foaf/0.1/givenName",
                        "valueExpr":
                          { "type": "NodeConstraint", "nodeKind": "literal" },
                        "min": 1, "max": "*"  },
                      { "type": "TripleConstraint",
                        "predicate": "http://xmlns.com/foaf/0.1/familyName",
                        "valueExpr":
                          { "type": "NodeConstraint", "nodeKind": "literal" } }
                    ]
                  }
                ]
              }
            }
          ]
        }),
        sxp: %{(schema
         (shapes
          (shape
           (label <http://schema.example/UserShape>)
           (oneOf
            (tripleConstraint <http://xmlns.com/foaf/0.1/name> (nodeConstraint literal))
            (eachOf
             (tripleConstraint <http://xmlns.com/foaf/0.1/givenName>
              (nodeConstraint literal)
              (min 1)
              (max "*"))
             (tripleConstraint <http://xmlns.com/foaf/0.1/familyName> (nodeConstraint literal)))))) )}
      },
      "Dependent Shape Example" => {
        shexc: %(
          PREFIX ex: <http://schema.example/>
          ex:IssueShape {
            ex:reproducedBy @ex:TesterShape
          }
          ex:TesterShape {
            ex:role [ex:testingRole]
          }
        ),
        shexj: %({
          "@context": "https://shexspec.github.io/context.jsonld",
          "type": "Schema",
          "shapes": [
           { "type": "Shape",
             "label": "http://schema.example/IssueShape",
             "expression":
            { "type": "TripleConstraint",
              "predicate": "http://schema.example/reproducedBy",
              "valueExpr":
              { "type": "ShapeRef",
                "reference": "http://schema.example/TesterShape" } } },
           { "type": "Shape",
             "label": "http://schema.example/TesterShape",
             "expression":
            { "type": "TripleConstraint",
              "predicate": "http://schema.example/role",
              "valueExpr":
              { "type": "NodeConstraint",
                "values": [ {"uri": "http://schema.example/testingRole"} ] } } }
          ] }),
        sxp: %{(schema
         (shapes
          (shape (label <http://schema.example/IssueShape>)
           (tripleConstraint <http://schema.example/reproducedBy>
            (shapeRef <http://schema.example/TesterShape>)) )
          (shape (label <http://schema.example/TesterShape>)
           (tripleConstraint <http://schema.example/role>
            (nodeConstraint (value <http://schema.example/testingRole>))))))}
      },
      "Recursion Example" => {
        shexc: %(PREFIX ex: <http://schema.example/> ex:IssueShape {ex:related @ex:IssueShape*}),
        shexj: %({
          "@context": "https://shexspec.github.io/context.jsonld",
          "type": "Schema",
          "shapes": [
           { "type": "Shape",
             "label": "http://schema.example/IssueShape",
             "expression":
            { "type": "TripleConstraint",
              "predicate": "http://schema.example/related",
              "valueExpr":
              { "type": "ShapeRef", "reference": "http://schema.example/IssueShape" },
              "min": 0, "max": "*"
            } } ] }),
        sxp: %{(schema
         (shapes (shape
          (label <http://schema.example/IssueShape>)
          (tripleConstraint <http://schema.example/related>
           (shapeRef <http://schema.example/IssueShape>)
           (min 0)
           (max "*")))))}
      },
      "Simple Repeated Property Examples" => {
        shexc: %(
          PREFIX ex: <http://schema.example/>
          ex:TestResultsShape {
            ex:val ["a" "b" "c"]+;
            ex:val ["b" "c" "d"]+
          }
        ),
        shexj: %({
          "@context": "https://shexspec.github.io/context.jsonld",
          "type": "Schema",
          "shapes": [
           { "type": "Shape",
             "label": "http://schema.example/TestResultsShape",
             "expression": {
              "type": "EachOf", "expressions": [
                { "type": "TripleConstraint",
                  "predicate": "http://schema.example/val",
                  "valueExpr":
                  { "type": "NodeConstraint",
                    "values": [
                      {"value": "a"},
                      {"value": "b"},
                      {"value": "c"}
                    ] }, "min": 1, "max": "*" },
                { "type": "TripleConstraint",
                  "predicate": "http://schema.example/val",
                  "valueExpr":
                  { "type": "NodeConstraint",
                    "values": [
                      {"value": "b"},
                      {"value": "c"},
                      {"value": "d"}
                    ] }, "min": 1, "max": "*" }
              ] } } ] }),
        sxp: %{(schema
         (shapes
          (shape
           (label <http://schema.example/TestResultsShape>)
           (eachOf
            (tripleConstraint <http://schema.example/val>
             (nodeConstraint (value "a") (value "b") (value "c"))
             (min 1)
             (max "*"))
            (tripleConstraint <http://schema.example/val>
             (nodeConstraint (value "b") (value "c") (value "d"))
             (min 1)
             (max "*")) )) ))}
      },
      "Repeated Property With Dependent Shapes Example" => {
        shexc: %(
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
        shexj: %({
          "@context": "https://shexspec.github.io/context.jsonld",
          "type": "Schema",
          "shapes": [
           { "type": "Shape",
             "label": "http://schema.example/IssueShape",
             "expression":
            { "type": "EachOf", "expressions": [
                { "type": "TripleConstraint",
                  "predicate": "http://schema.example/reproducedBy",
                  "valueExpr":
                  { "type": "ShapeRef",
                    "reference": "http://schema.example/TesterShape" } },
                { "type": "TripleConstraint",
                  "predicate": "http://schema.example/reproducedBy",
                  "valueExpr":
                  { "type": "ShapeRef",
                    "reference": "http://schema.example/ProgrammerShape" } }
              ] } },
           { "type": "Shape",
             "label": "http://schema.example/TesterShape",
             "expression":
            { "type": "TripleConstraint",
              "predicate": "http://schema.example/role",
              "valueExpr":
              { "type": "NodeConstraint",
                "values": [ {"uri": "http://schema.example/testingRole"} ] } } },
           { "type": "Shape",
             "label": "http://schema.example/ProgrammerShape",
             "expression":
            { "type": "TripleConstraint",
              "predicate": "http://schema.example/department",
              "valueExpr":
              { "type": "NodeConstraint",
                "values": [ {"uri": "http://schema.example/ProgrammingDepartment"} ] } } }
          ] }),
        sxp: %{(schema
         (shapes
          (shape
           (label <http://schema.example/IssueShape>)
             (eachOf
              (tripleConstraint <http://schema.example/reproducedBy>
               (shapeRef <http://schema.example/TesterShape>))
              (tripleConstraint <http://schema.example/reproducedBy>
               (shapeRef <http://schema.example/ProgrammerShape>)) ))
          (shape
          (label <http://schema.example/TesterShape>)
           (tripleConstraint <http://schema.example/role>
            (nodeConstraint (value <http://schema.example/testingRole>))) )
          (shape
          (label <http://schema.example/ProgrammerShape>)
           (tripleConstraint <http://schema.example/department>
            (nodeConstraint (value <http://schema.example/ProgrammingDepartment>)))
          )) )}
      },
      "Complex Values Constraint Example 2" => {
        shexc: %(
          PREFIX ex:   <http://schema.example/>
          PREFIX foaf: <http://xmlns.com/foaf/>
          PREFIX xsd:  <http://www.w3.org/2001/XMLSchema#>
          PREFIX rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

          <IssueShape> CLOSED EXTRA rdf:type
          {                           
              a [ex:Issue];
              ex:state [ex:unassigned ex:assigned]; 
                                       
              ex:reportedBy @<UserShape>;   
              ex:reportedOn xsd:dateTime;         
              (                                   
                ex:reproducedBy @<EmployeeShape>;  
                ex:reproducedOn xsd:dateTime OR xsd:date 
              )?;
              ^ex:related @<IssueShape>*            
          }

          <UserShape> PATTERN "^http:/example.org/.*" {                     
              (                                   
                 foaf:name xsd:string             
               |                                  
                 foaf:givenName xsd:string+;      
                 foaf:familyName xsd:string
              );     
              foaf:mbox IRI              
          }

          <EmployeeShape> {        
              foaf:phone IRI*;          
              foaf:mbox IRI             
          } AND {
              ( foaf:phone PATTERN "^tel:\\\\+33"; 
                foaf:mbox PATTERN "\\\\.fr$" )?;
              ( foaf:phone PATTERN "^tel:\\\\+44"; 
                foaf:mbox PATTERN "\\\\.uk$")?
          }
        ),
        sxp: %{(schema
         (shapes
          (shape
           (label <IssueShape>)
             (extra <http://www.w3.org/1999/02/22-rdf-syntax-ns#type>) closed
             (eachOf
              (tripleConstraint a (nodeConstraint (value <http://schema.example/Issue>)))
              (tripleConstraint <http://schema.example/state>
               (nodeConstraint
                (value <http://schema.example/unassigned>)
                (value <http://schema.example/assigned>)) )
              (tripleConstraint <http://schema.example/reportedBy> (shapeRef <UserShape>))
              (tripleConstraint <http://schema.example/reportedOn>
               (nodeConstraint (datatype <http://www.w3.org/2001/XMLSchema#dateTime>)))
              (eachOf
               (tripleConstraint <http://schema.example/reproducedBy> (shapeRef <EmployeeShape>))
               (tripleConstraint <http://schema.example/reproducedOn>
                (or
                 (nodeConstraint (datatype <http://www.w3.org/2001/XMLSchema#dateTime>))
                 (nodeConstraint (datatype <http://www.w3.org/2001/XMLSchema#date>))) )
               (min 0)
               (max 1))
              (tripleConstraint inverse <http://schema.example/related>
               (shapeRef <IssueShape>)
               (min 0)
               (max "*")) )
              )
           (and
            (label <UserShape>)
             (nodeConstraint (pattern "^http:/example.org/.*"))
             (shape
              (eachOf
               (oneOf
                (tripleConstraint <http://xmlns.com/foaf/name>
                 (nodeConstraint (datatype <http://www.w3.org/2001/XMLSchema#string>)))
                (eachOf
                 (tripleConstraint <http://xmlns.com/foaf/givenName>
                  (nodeConstraint (datatype <http://www.w3.org/2001/XMLSchema#string>))
                  (min 1)
                  (max "*"))
                 (tripleConstraint <http://xmlns.com/foaf/familyName>
                  (nodeConstraint (datatype <http://www.w3.org/2001/XMLSchema#string>)))
                ))
               (tripleConstraint <http://xmlns.com/foaf/mbox> (nodeConstraint iri))) ))
           (and
            (label <EmployeeShape>)
             (shape
              (eachOf
               (tripleConstraint <http://xmlns.com/foaf/phone> (nodeConstraint iri) (min 0) (max "*"))
               (tripleConstraint <http://xmlns.com/foaf/mbox> (nodeConstraint iri))) )
             (shape
              (eachOf
               (eachOf
                (tripleConstraint <http://xmlns.com/foaf/phone>
                 (nodeConstraint (pattern "^tel:\\\\+33")))
                (tripleConstraint <http://xmlns.com/foaf/mbox> (nodeConstraint (pattern "\\\\.fr$")))
                (min 0)
                (max 1))
               (eachOf
                (tripleConstraint <http://xmlns.com/foaf/phone>
                 (nodeConstraint (pattern "^tel:\\\\+44")))
                (tripleConstraint <http://xmlns.com/foaf/mbox> (nodeConstraint (pattern "\\\\.uk$")))
                (min 0)
                (max 1)) )) )) )}
      },
      "Closed shape expression" => {
        shexc: %(
          PREFIX ex: <http://schema.example/>
          PREFIX xsd:  <http://www.w3.org/2001/XMLSchema#>
          # ShEx schema

          <IssueShape>

          CLOSED {                 
              ex:state      [ex:unassigned ex:assigned] ; 
              ex:reportedBy @<UserShape> ;   
              ex:reportedOn xsd:dateTime OR xsd:date ;
              ex:related    @<IssueShape>* ;
              ^ex:related   @<IssueShape>*
          }

          <UserShape> {
              a PATTERN "http://example.org/User#.*"
          }
        ),
        sxp: %{(schema
         (shapes
          (shape (label <IssueShape>) closed
           (eachOf
            (tripleConstraint <http://schema.example/state>
             (nodeConstraint
              (value <http://schema.example/unassigned>)
              (value <http://schema.example/assigned>)) )
            (tripleConstraint <http://schema.example/reportedBy> (shapeRef <UserShape>))
            (tripleConstraint <http://schema.example/reportedOn>
             (or
              (nodeConstraint (datatype <http://www.w3.org/2001/XMLSchema#dateTime>))
              (nodeConstraint (datatype <http://www.w3.org/2001/XMLSchema#date>))) )
            (tripleConstraint <http://schema.example/related>
             (shapeRef <IssueShape>)
             (min 0)
             (max "*"))
            (tripleConstraint inverse <http://schema.example/related>
             (shapeRef <IssueShape>)
             (min 0)
             (max "*")) ) )
          (shape (label <UserShape>)
           (tripleConstraint a (nodeConstraint (pattern "http://example.org/User#.*"))))))}
      },
      "Closed shape expression with EXTRA modifier" => {
        shexc: %(
          PREFIX ex: <http://schema.example/>
          PREFIX foaf: <http://xmlns.com/foaf/>
          PREFIX xsd:  <http://www.w3.org/2001/XMLSchema#>
          PREFIX rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
          # ShEx schema
          <UserShape> CLOSED EXTRA rdf:type foaf:mbox {

              rdf:type [foaf:Person] ;
              rdf:type [ex:User] ;
              (                                   
                 foaf:name xsd:string 
               |                                  
                 foaf:givenName xsd:string+ ;      
                 foaf:familyName xsd:string
              );
              foaf:mbox IRI

          }
        ),
        sxp: %{(schema
         (shapes (shape (label <UserShape>)
          (extra <http://www.w3.org/1999/02/22-rdf-syntax-ns#type>
                 <http://xmlns.com/foaf/mbox>)
          closed
          (eachOf
           (tripleConstraint <http://www.w3.org/1999/02/22-rdf-syntax-ns#type>
            (nodeConstraint (value <http://xmlns.com/foaf/Person>)))
           (tripleConstraint <http://www.w3.org/1999/02/22-rdf-syntax-ns#type>
            (nodeConstraint (value <http://schema.example/User>)))
           (oneOf
            (tripleConstraint <http://xmlns.com/foaf/name>
             (nodeConstraint (datatype <http://www.w3.org/2001/XMLSchema#string>)))
            (eachOf
             (tripleConstraint <http://xmlns.com/foaf/givenName>
              (nodeConstraint (datatype <http://www.w3.org/2001/XMLSchema#string>))
              (min 1)
              (max "*"))
             (tripleConstraint <http://xmlns.com/foaf/familyName>
              (nodeConstraint (datatype <http://www.w3.org/2001/XMLSchema#string>))) ))
           (tripleConstraint <http://xmlns.com/foaf/mbox> (nodeConstraint iri))))))}
      },
      "Non closed shape expression" => {
        shexc: %(
          PREFIX ex: <http://schema.example/>
          PREFIX xsd:  <http://www.w3.org/2001/XMLSchema#>
          # ShEx schema
          <SomeShape> {
              ex:p xsd:int* ;
              ( ex:q xsd:int | ex:r IRI )? 
          }
        ),
        sxp: %{(schema
         (shapes
          (shape
           (label <SomeShape>)
           (eachOf
            (tripleConstraint <http://schema.example/p>
             (nodeConstraint (datatype <http://www.w3.org/2001/XMLSchema#int>))
             (min 0)
             (max "*"))
            (oneOf
             (tripleConstraint <http://schema.example/q>
              (nodeConstraint (datatype <http://www.w3.org/2001/XMLSchema#int>)))
             (tripleConstraint <http://schema.example/r> (nodeConstraint iri))
             (min 0)
             (max 1)) )) ))
        }},
      "Complex shape definition" => {
        shexc: %(
          PREFIX ex: <http://schema.example/>
          PREFIX foaf: <http://xmlns.com/foaf/>
          # ShEx schema

          <EmployeeShape>
          PATTERN "^http:/example.org/.*"

          CLOSED {        
              foaf:phone IRI*;          
              foaf:mbox IRI             
          }

          AND 

          CLOSED {
            ( foaf:phone PATTERN "^tel:\\\\+33"; 
              foaf:mbox PATTERN "\\\\.fr$" )?;
            ( foaf:phone PATTERN "^tel:\\\\+44"; 
              foaf:mbox PATTERN "\\\\.uk$")?
          }
        ),
        sxp: %{(schema
         (shapes
          (and
           (label <EmployeeShape>)
           (nodeConstraint (pattern "^http:/example.org/.*"))
           (shape closed
            (eachOf
             (tripleConstraint <http://xmlns.com/foaf/phone> (nodeConstraint iri) (min 0) (max "*"))
             (tripleConstraint <http://xmlns.com/foaf/mbox> (nodeConstraint iri))))
           (shape closed
            (eachOf
             (eachOf
              (tripleConstraint <http://xmlns.com/foaf/phone>
               (nodeConstraint (pattern "^tel:\\\\+33")))
              (tripleConstraint <http://xmlns.com/foaf/mbox> (nodeConstraint (pattern "\\\\.fr$")))
              (min 0)
              (max 1))
             (eachOf
              (tripleConstraint <http://xmlns.com/foaf/phone>
               (nodeConstraint (pattern "^tel:\\\\+44")))
              (tripleConstraint <http://xmlns.com/foaf/mbox> (nodeConstraint (pattern "\\\\.uk$")))
              (min 0)
              (max 1)) ) )) ))}
      },
      "Negated triple expression" => {
        shexc: %(
          PREFIX ex: <http://schema.example/>
          PREFIX xsd:  <http://www.w3.org/2001/XMLSchema#>
          # ShEx schema

          <SomeShape> 
          CLOSED {
              ex:p xsd:int* ;
              ( ex:q xsd:int {0,0}  
                | ex:r IRI )? 
          }
        ),
        sxp: %{(schema
         (shapes
          (shape
           (label <SomeShape>)
           closed
           (eachOf
            (tripleConstraint <http://schema.example/p>
             (nodeConstraint (datatype <http://www.w3.org/2001/XMLSchema#int>))
             (min 0)
             (max "*"))
            (oneOf
             (tripleConstraint <http://schema.example/q>
              (nodeConstraint (datatype <http://www.w3.org/2001/XMLSchema#int>))
              (min 0)
              (max 0))
             (tripleConstraint <http://schema.example/r> (nodeConstraint iri))
             (min 0)
             (max 1)) ))))}
      },
    }.each do |name, params|
      it "#{name} (shexc)" do
        expect(params[:shexc]).to generate(params[:sxp].gsub(/^        /m, ''), logger: RDF::Spec.logger)
      end

      if params[:shexj]
        it "#{name} (shexj)" do
          expect(params[:shexj]).to generate(params[:sxp].gsub(/^        /m, ''), logger: RDF::Spec.logger, format: :shexj)
        end

        it "#{name} generates shexj from shexc" do
          expression = ShEx.parse(params[:shexc])
          hash = expression.to_h
          expect(hash).to produce(JSON.parse(params[:shexj]), logger: RDF::Spec.logger)
        end
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
      "Inclusion 1" => {
        input: %(<http://e/S1> {&<http://e/MissingShape>}),
        result: ShEx::StructureError
      },
      "This negated self-reference violates the negation requirement" => {
        input: %(
          PREFIX ex: <http://schema.example/>
          ex:S NOT @ex:S
        ),
        result: ShEx::StructureError
      },
      "This negated, indirect self-reference violates the negation requirement" => {
        input: %(
          PREFIX ex: <http://schema.example/>
          ex:S NOT @ex:T
          ex:T @ex:S
        ),
        result: ShEx::StructureError
      },
      "This doubly-negated self-reference does not violate the negation requirement" => {
        input: %(
          PREFIX ex: <http://schema.example/>
          ex:S NOT (IRI OR NOT @ex:S)
        ),
        result: %{(schema
           (shapes
             (not 
               (label <http://schema.example/S>)
               (or (nodeConstraint iri)
                   (not (shapeRef <http://schema.example/S>)))) ))}
      },
      "This self-reference on a predicate designated as extra violates the negation requirement" => {
        input: %(PREFIX ex: <http://schema.example/> ex:S EXTRA ex:p {ex:p @ex:S}),
        result: ShEx::StructureError
      },
      "The same shape with a negated self-reference still violates the negation requirement because the reference occurs with a ShapeNot" => {
        input: %(PREFIX ex: <http://schema.example/> ex:S EXTRA ex:p {ex:p NOT @ex:S}),
        result: ShEx::StructureError
      },
    }.each do |name, params|
      it name do
        case name
        when "This negated, indirect self-reference violates the negation requirement"
          pending "Checking references through indirects"
        when "The same shape with a negated self-reference still violates the negation requirement because the reference occurs with a ShapeNot"
          pending "Negated references"
        end
        result = params[:result]
        result.gsub!(/^          /m, '') if result.is_a?(String)
        expect(params[:input]).to generate(result, validate: true, logger: RDF::Spec.logger)
      end
    end
  end

  require 'suite_helper'

  %w(schemas negativeSyntax negativeStructure).each do |dir|
    manifest = Fixtures::SuiteTest::BASE + "#{dir}/manifest.jsonld"
    Fixtures::SuiteTest::Manifest.open(manifest) do |m|
      describe m.attributes['rdfs:comment'] do
        m.entries.each do |t|
          specify "#{t.name} – #{t.comment}#{' (negative)' if t.negative_test?}" do
            validate = true
            case t.name
            when 'kitchenSink'
              validate = false # Has self-included shape
            when '_all'
              #validate = false # Has self-included shape
              pending("Ordering of shapes in schema")
            when 'openopen1dotOr1dotclose'
              pending("Our grammar allows nested bracketedTripleExpr")
            when '1focusRefANDSelfdot'
              #pending("Is self referencing (OK?) and includes an empty shape (OK?)")
            end

            t.debug = ["info: #{t.inspect}", "schema: #{t.schema_source}"]

            if t.positive_test?
              begin
                expression = ShEx.parse(t.schema_source, validate: validate, logger: RDF::Spec.logger)
                hash = expression.to_h
                shexj = JSON.parse t.schema_json
                expect(hash).to produce(shexj, logger: RDF::Spec.logger)
              rescue IOError
                # JSON file not there, ignore
              end
            else
              exp = t.structure_test? ? ShEx::StructureError : ShEx::ParseError
              expect(t.schema_source).to generate(exp, validate: validate, logger: RDF::Spec.logger)
            end
          end
        end
      end
    end
  end

  context "Positive Validation Syntax Tests" do
    Dir.glob("spec/shexTest/validation/*.shex").
      map {|f| f.split('/').last.sub('.shex', '')}.
      each do |file|
      it file do
        input = File.read File.expand_path("../shexTest/validation/#{file}.shex", __FILE__)

        expect {ShEx.parse(input)}.not_to raise_error
      end
    end
  end
end
