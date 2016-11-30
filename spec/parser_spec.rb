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
      "Node Kind Example 1" => {
        shexc: %(PREFIX ex: <http://schema.example/> ex:IssueShape {ex:state IRI}),
        shexj: %({ "type": "Schema", "shapes": {
          "http://schema.example/IssueShape": {
          "type": "Shape", "expression": {
            "type": "TripleConstraint", "predicate": "http://schema.example/state",
            "valueExpr": { "type": "NodeConstraint", "nodeKind": "iri" } } } } }),
        sxp: %{(schema
         (prefix (("ex" <http://schema.example/>)))
         (shape <http://schema.example/IssueShape>
          (tripleConstraint <http://schema.example/state> (nodeConstraint iri))) )}
      },
      "Datatype Example 1" => {
        shexc: %(
          PREFIX ex: <http://schema.example/>
          PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
          ex:IssueShape {ex:submittedOn xsd:dateTime}
        ),
        shexj: %({ "type": "Schema", "shapes": {
          "http://schema.example/IssueShape": {
            "type": "Shape", "expression": {
              "type": "TripleConstraint", "predicate": "http://schema.example/submittedOn",
              "valueExpr": {
                "type": "NodeConstraint",
                "datatype": "http://www.w3.org/2001/XMLSchema#dateTime"
              } } } } }),
        sxp: %{(schema
         (prefix (("ex" <http://schema.example/>) ("xsd" <http://www.w3.org/2001/XMLSchema#>)))
         (shape <http://schema.example/IssueShape>
          (tripleConstraint <http://schema.example/submittedOn>
           (nodeConstraint datatype <http://www.w3.org/2001/XMLSchema#dateTime>)) ))}
      },
      "String Facets Example 1" => {
        shexc: %(
          PREFIX ex: <http://schema.example/>
          PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
          ex:IssueShape {ex:submittedOn rdf:langString}),
        shexj: %({ "type": "Schema", "shapes": {
          "http://schema.example/IssueShape": {
            "type": "Shape", "expression": {
              "type": "TripleConstraint",
              "predicate": "http://schema.example/submittedOn",
              "valueExpr": {
                "type": "NodeConstraint",
                "datatype": "http://www.w3.org/1999/02/22-rdf-syntax-ns#langString"
              } } } } }),
        sxp: %{(schema
         (prefix
          (
           ("ex" <http://schema.example/>)
           ("rdf" <http://www.w3.org/1999/02/22-rdf-syntax-ns#>)) )
         (shape <http://schema.example/IssueShape>
          (tripleConstraint <http://schema.example/submittedOn>
           (nodeConstraint datatype <http://www.w3.org/1999/02/22-rdf-syntax-ns#langString>)) ))}
      },
      "String Facets Example 2" => {
        shexc: %(PREFIX ex: <http://schema.example/> ex:IssueShape {ex:submittedBy PATTERN "genUser[0-9]+"}),
        shexj: %({ "type": "Schema", "shapes": {
          "http://schema.example/IssueShape": {
            "type": "Shape", "expression": {
              "type": "TripleConstraint",
              "predicate": "http://schema.example/submittedBy",
              "valueExpr": { "type": "NodeConstraint", "pattern": "genUser[0-9]+" }
        } } } }),
        sxp: %{(schema
         (prefix (("ex" <http://schema.example/>)))
         (shape <http://schema.example/IssueShape>
          (tripleConstraint <http://schema.example/submittedBy>
           (nodeConstraint (pattern "genUser[0-9]+"))) ))}
      },
      "Numeric Facets Example 1" => {
        shexc: %(PREFIX ex: <http://schema.example/> ex:IssueShape {ex:confirmations MININCLUSIVE 1}),
        shexj: %({ "type": "Schema", "shapes": {
          "http://schema.example/IssueShape": {
            "type": "Shape", "expression": {
              "type": "TripleConstraint",
              "predicate": "http://schema.example/confirmations",
              "valueExpr": { "type": "NodeConstraint", "mininclusive": 1 } } } } }),
        sxp: %{(schema
         (prefix (("ex" <http://schema.example/>)))
         (shape <http://schema.example/IssueShape>
          (tripleConstraint <http://schema.example/confirmations>
           (nodeConstraint (mininclusive 1))) ))}
      },
      "Values Constraint Example 1" => {
        shexc: %(PREFIX ex: <http://schema.example/> ex:NoActionIssueShape {ex:state [ ex:Resolved ex:Rejected ]}),
        shexj: %({ "type": "Schema", "shapes": {
          "http://schema.example/NoActionIssueShape": {
            "type": "Shape", "expression": {
              "type": "TripleConstraint",
              "predicate": "http://schema.example/state",
              "valueExpr": {
                "type": "NodeConstraint", "values": [
                  "http://schema.example/Resolved",
                  "http://schema.example/Rejected" ] } } } } }),
        sxp: %{(schema
         (prefix (("ex" <http://schema.example/>)))
         (shape <http://schema.example/NoActionIssueShape>
          (tripleConstraint <http://schema.example/state>
           (nodeConstraint
            (value <http://schema.example/Resolved>)
            (value <http://schema.example/Rejected>)) )) )}
      },
      "Value Constraints Example 2" => {
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
        shexj: %({ "type": "Schema", "shapes": {
          "http://schema.example/EmployeeShape": {
            "type": "Shape", "expression": {
              "type": "TripleConstraint",
              "predicate": "http://xmlns.com/foaf/0.1/mbox",
              "valueExpr": {
                "type": "NodeConstraint", "values": [
                  "\"N/A\"",
                  { "type": "StemRange", "stem": "mailto:engineering-" },
                  { "type": "StemRange", "stem": "mailto:sales-", "exclusions": [
                      { "type": "Stem", "stem": "mailto:sales-contacts" },
                      { "type": "Stem", "stem": "mailto:sales-interns" }
                    ] }
                ] } } } } }),
        sxp: %{(schema
         (prefix (("ex" <http://schema.example/>) ("foaf" <http://xmlns.com/foaf/0.1/>)))
         (shape <http://schema.example/EmployeeShape>
          (tripleConstraint <http://xmlns.com/foaf/0.1/mbox>
           (nodeConstraint
            (value "N/A")
            (value (stemRange <mailto:engineering->))
            (value
             (stemRange <mailto:sales->
              (exclusions (stem (<mailto:sales-contacts>)) (stem (<mailto:sales-interns>)))) )) )) )}
      },
      "Value Constraints Example 3" => {
        shexc: %(
          PREFIX ex: <http://schema.example/>
          PREFIX foaf: <http://xmlns.com/foaf/0.1/>
          ex:EmployeeShape {
              foaf:mbox [ . - <mailto:engineering->~ - <mailto:sales->~ ]
            }
        ),
        shexj: %({ "type": "Schema", "shapes": {
          "http://schema.example/EmployeeShape": {
            "type": "Shape", "expression": {
              "type": "TripleConstraint",
              "predicate": "http://xmlns.com/foaf/0.1/mbox",
              "valueExpr": {
                "type": "NodeConstraint", "values": [
                  { "type": "Wildcard", "exclusions": [
                      { "type": "Stem", "stem": "mailto:engineering-" },
                      { "type": "Stem", "stem": "mailto:sales-" }
                    ] }
                ] } } } } }),
        sxp: %{(schema
         (prefix (("ex" <http://schema.example/>) ("foaf" <http://xmlns.com/foaf/0.1/>)))
         (shape <http://schema.example/EmployeeShape>
          (tripleConstraint <http://xmlns.com/foaf/0.1/mbox>
           (nodeConstraint
            (value
             (stemRange wildcard (exclusions (stem (<mailto:engineering->)) (stem (<mailto:sales->))))) )) ))}
      },
      # Spec FIXME: added "."
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
        shexj: %({ "type":"Schema", "shapes": {
          "http://schema.example/PersonShape": {
            "type":"Shape", "expression": {
              "type": "TripleConstraint",
              "predicate": "http://xmlns.com/foaf/0.1/name"
            } },
          "http://schema.example/EmployeeShape": {
            "type":"Shape", "expression": { "type":"ShapeAnd", "shapeExprs": [
              { "type": "Inclusion", "include": "http://schema.example/PersonShape" }
              { "type": "TripleConstraint",
                "predicate": "http://schema.example/employeeNumber" }
                ] } } } }),
        sxp: %{(schema
         (prefix (("ex" <http://schema.example/>) ("foaf" <http://xmlns.com/foaf/0.1/>)))
         (shape <http://schema.example/PersonShape>
          (tripleConstraint <http://xmlns.com/foaf/0.1/name>))
         (shape <http://schema.example/EmployeeShape>
          (eachOf
           (inclusion <http://schema.example/PersonShape>)
           (tripleConstraint <http://schema.example/employeeNumber>)) ))}
      },
      "Double Negated reference" => {
        shexc: %(PREFIX ex: <http://schema.example/> ex:S NOT (IRI OR NOT @ex:S)),
        shexj: %({ "type": "Schema", "shapes": {
          "http://schema.example/#S": {
            "type": "ShapeNot", "shapeExpr": {
              "type": "ShapeOr", "shapeExprs": [
                { "type": "NodeConstraint", "nodeKind": "iri" },
                { "type": "ShapeNot", "shapeExpr": {
                    "type": "ShapeRef", "reference": "http://schema.example/#S" } }
      ] } } } }),
        sxp: %{(schema
         (prefix (("ex" <http://schema.example/>)))
         (shape <http://schema.example/S>
          (not (or (nodeConstraint iri) (not (shapeRef <http://schema.example/S>)))))
        )}
      },
      # Spec FIXME: added "."
      "Semantic Actions Example 1" => {
        shexc: %(PREFIX ex: <http://schema.example/> ex:S1 {
          ex:p1 . %Test:{ print(s) %} %Test:{ print(o) %}
        }),
        shexj: %({ "type": "Schema", "shapes":{
          "http://a.example/S1": {
            "type": "Shape", "expression": {
              "type": "TripleConstraint", "predicate": "http://a.example/p1",
              "semActs": [
                { "type": "SemAct", "code": " print(s) ",
                  "name": "http://shex.io/extensions/Test/" },
                { "type": "SemAct", "code": " print(o) ",
                  "name": "http://shex.io/extensions/Test/" } ] } } } }),
        sxp: %{(schema
         (prefix (("ex" <http://schema.example/>)))
         (shape <http://schema.example/S1>
          (tripleConstraint <http://schema.example/p1>
           (semact (<> " print(s) "))
           (semact (<> " print(o) "))) ))}
      },
      "Annotations Example 1" => {
        shexc: %(
          PREFIX ex: <http://schema.example/>
          PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
          ex:IssueShape {
            ex:status .
                // rdfs:comment "\\\"Represents reported software issues.\\\""
                // rdfs:label "\\\"softare issue\\\""
          }
        ),
        shexj: %({ "type": "Schema", "shapes":{
          "http://schema.example/IssueShape": {
            "type": "Shape", "expression": {
              "type": "TripleConstraint",
              "predicate": "http://schema.example/status",
              "annotations": [
                 { "type": "Annotation",
                   "predicate": "http://www.w3.org/2000/01/rdf-schema#comment",
                   "object": "\"Represents reported software issues.\"" },
                 { "type": "Annotation",
                   "predicate": "http://www.w3.org/2000/01/rdf-schema#label",
                   "object": "\"softare issue\"" } ] } } }),
        sxp: %{(schema
         (prefix
          (("ex" <http://schema.example/>) ("rdfs" <http://www.w3.org/2000/01/rdf-schema#>)))
         (shape <http://schema.example/IssueShape>
          (tripleConstraint <http://schema.example/status>
           (annotation <http://www.w3.org/2000/01/rdf-schema#comment>
            "\\\"Represents reported software issues.\\\"" )
           (annotation <http://www.w3.org/2000/01/rdf-schema#label> "\\\"softare issue\\\"")) ))}
      },
      "Validation Example 1" => {
        shexc: %(
          PREFIX ex: <http://schema.example/>
          PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
          ex:IntConstraint xsd:integer
        ),
        shexj: %({ "type": "Schema", "shapes":
          { "http://schema.example/IntConstraint":
            { "type": "NodeConstraint",
              "datatype": "http://www.w3.org/2001/XMLSchema#integer"
            } } }),
        sxp: %{(schema
         (prefix (("ex" <http://schema.example/>) ("xsd" <http://www.w3.org/2001/XMLSchema#>)))
         (shape <http://schema.example/IntConstraint>
          (nodeConstraint datatype <http://www.w3.org/2001/XMLSchema#integer>)) )}
      },
      "Validation Example 2" => {
        shexc: %(PREFIX ex: <http://schema.example/> ex:UserShape {ex:shoeSize .}),
        shexj: %({ "type": "Schema", "shapes": {
          "http://schema.example/UserShape":
          { "type": "Shape", "expression":
            { "type": "TripleConstraint",
              "predicate": "http://schema.example/shoeSize"
              } } } }),
        sxp: %{(schema
         (prefix (("ex" <http://schema.example/>)))
         (shape <http://schema.example/UserShape>
          (tripleConstraint <http://schema.example/shoeSize>)) )}
      },
      "Validation Example 3" => {
        shexc: %(PREFIX ex: <http://schema.example/> ex:UserShape EXTRA a {a [ex:Teacher]}),
        shexj: %({ "type": "Schema", "shapes": {
          "http://schema.example/UserShape":
          { "type": "Shape", "expression":
            { "type": "TripleConstraint",
              "extra": ["http://www.w3.org/1999/02/22-rdf-syntax-ns#type"],
              "predicate": "http://www.w3.org/1999/02/22-rdf-syntax-ns#type",
              "valueExpr":
              { "type": "NodeConstraint",
                "values": ["http://schema.example/Teacher"]
              } } } } }),
        sxp: %{(schema
         (prefix (("ex" <http://schema.example/>)))
         (shape <http://schema.example/UserShape>
          (tripleConstraint a (nodeConstraint (value <http://schema.example/Teacher>)))
          (extra a)) )}
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
        shexj: %({ "type": "Schema", "shapes": {
          "http://schema.example/UserShape":
          { "type": "Shape", "expression":
             {"type": "SomeOf", "expressions": [
                { "type": "TripleConstraint",
                  "predicate": "http://xmlns.com/foaf/0.1/name",
                  "valueExpr":
                    { "type": "NodeConstraint", "nodeKind": "literal" } },
                { "type": "EachOf", "expressions": [
                    { "type": "TripleConstraint", "min": 1, "max": "*" ,
                      "predicate": "http://xmlns.com/foaf/0.1/givenName",
                      "valueExpr":
                        { "type": "NodeConstraint", "nodeKind": "literal" } },
                    { "type": "TripleConstraint",
                      "predicate": "http://xmlns.com/foaf/0.1/familyName",
                      "valueExpr":
                        { "type": "NodeConstraint", "nodeKind": "literal" } }
                ] }
             ] }
         } } }),
        sxp: %{(schema
         (prefix (("ex" <http://schema.example/>) ("foaf" <http://xmlns.com/foaf/0.1/>)))
         (shape <http://schema.example/UserShape>
          (someOf
           (tripleConstraint <http://xmlns.com/foaf/0.1/name> (nodeConstraint literal))
           (eachOf
            (tripleConstraint <http://xmlns.com/foaf/0.1/givenName>
             (nodeConstraint literal)
             (min 1)
             (max "*"))
            (tripleConstraint <http://xmlns.com/foaf/0.1/familyName> (nodeConstraint literal))) )) )}
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
        shexj: %({ "type": "Schema", "shapes": {
          "http://schema.example/IssueShape":
          { "type": "Shape", "expression":
            { "type": "TripleConstraint",
              "predicate": "http://schema.example/reproducedBy",
              "valueExpr":
              { "type": "ShapeRef",
                "reference": "http://schema.example/TesterShape" } } },
          "http://schema.example/TesterShape":
          { "type": "Shape", "expression":
            { "type": "TripleConstraint",
              "predicate": "http://schema.example/role",
              "valueExpr":
              { "type": "NodeConstraint",
                "values": [ "http://schema.example/testingRole" ] } } }
          } }),
        sxp: %{(schema
         (prefix (("ex" <http://schema.example/>)))
         (shape <http://schema.example/IssueShape>
          (tripleConstraint <http://schema.example/reproducedBy>
           (shapeRef <http://schema.example/TesterShape>)) )
         (shape <http://schema.example/TesterShape>
          (tripleConstraint <http://schema.example/role>
           (nodeConstraint (value <http://schema.example/testingRole>))) ))}
      },
      "Recursion Example" => {
        shexc: %(PREFIX ex: <http://schema.example/> ex:IssueShape {ex:related @ex:IssueShape*}),
        shexj: %({ "type": "Schema", "shapes": {
          "http://schema.example/IssueShape":
          { "type": "Shape", "expression":
            { "type": "TripleConstraint", "min": 0, "max": "*",
              "predicate": "http://schema.example/related",
              "valueExpr":
              { "type": "ShapeRef", "reference": "http://schema.example/IssueShape" }
            } } } }),
        sxp: %{(schema
         (prefix (("ex" <http://schema.example/>)))
         (shape <http://schema.example/IssueShape>
          (tripleConstraint <http://schema.example/related>
           (shapeRef <http://schema.example/IssueShape>)
           (min 0)
           (max "*")) ))}
      },
      "Simple Repeated Property Examples" => {
        shexc: %(
          PREFIX ex: <http://schema.example/>
          ex:TestResultsShape {
            ex:val ["a" "b" "c"]+;
            ex:val ["b" "c" "d"]+
          }
        ),
        shexj: %({ "type": "Schema", "shapes": {
          "http://schema.example/TestResultsShape":
          { "type": "Shape", "expression": {
              "type": "EachOf", "expressions": [
                { "type": "TripleConstraint", "min": 1, "max": "*",
                  "predicate": "http://schema.example/val",
                  "valueExpr":
                  { "type": "NodeConstraint",
                    "values": [ "\"a\"", "\"b\"", "\"c\"" ] } },
                { "type": "TripleConstraint", "min": 1, "max": "*",
                  "predicate": "http://schema.example/val",
                  "valueExpr":
                  { "type": "NodeConstraint",
                    "values": [ "\"b\"", "\"c\"", "\"d\"" ] } }
              ] } } } }),
        sxp: %{(schema
       (prefix (("ex" <http://schema.example/>)))
       (shape <http://schema.example/TestResultsShape>
        (eachOf
         (tripleConstraint <http://schema.example/val>
          (nodeConstraint (value "a") (value "b") (value "c"))
          (min 1)
          (max "*"))
         (tripleConstraint <http://schema.example/val>
          (nodeConstraint (value "b") (value "c") (value "d"))
          (min 1)
          (max "*")) )) )}
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
        shexj: %({ "type": "Schema", "shapes": {
          "http://schema.example/IssueShape":
          { "type": "Shape", "expression":
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
          "http://schema.example/TesterShape":
          { "type": "Shape", "expression":
            { "type": "TripleConstraint",
              "predicate": "http://schema.example/role",
              "valueExpr":
              { "type": "NodeConstraint",
                "values": [ "http://schema.example/testingRole" ] } } },
          "http://schema.example/ProgrammerShape":
          { "type": "Shape", "expression":
            { "type": "TripleConstraint",
              "predicate": "http://schema.example/department",
              "valueExpr":
              { "type": "NodeConstraint",
                "values": [ "http://schema.example/ProgrammingDepartment" ] } } }
          } }),
        sxp: %{(schema
         (prefix (("ex" <http://schema.example/>)))
         (shape <http://schema.example/IssueShape>
          (eachOf
           (tripleConstraint <http://schema.example/reproducedBy>
            (shapeRef <http://schema.example/TesterShape>))
           (tripleConstraint <http://schema.example/reproducedBy>
            (shapeRef <http://schema.example/ProgrammerShape>)) ))
         (shape <http://schema.example/TesterShape>
          (tripleConstraint <http://schema.example/role>
           (nodeConstraint (value <http://schema.example/testingRole>))) )
         (shape <http://schema.example/ProgrammerShape>
          (tripleConstraint <http://schema.example/department>
           (nodeConstraint (value <http://schema.example/ProgrammingDepartment>))) ))}
      },
      # Spec FIXME: RREFIX => PREFIX
      "Value Constraint Example 2" => {
        shexc: %(
          PREFIX ex:   <http://ex.example/#>
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
         (prefix
          (
           ("ex" <http://ex.example/#>)
           ("foaf" <http://xmlns.com/foaf/>)
           ("xsd" <http://www.w3.org/2001/XMLSchema#>)
           ("rdf" <http://www.w3.org/1999/02/22-rdf-syntax-ns#>)) )
         (shape <IssueShape>
          (eachOf
           (tripleConstraint a (nodeConstraint (value <http://ex.example/#Issue>)))
           (tripleConstraint <http://ex.example/#state>
            (nodeConstraint
             (value <http://ex.example/#unassigned>)
             (value <http://ex.example/#assigned>)) )
           (tripleConstraint <http://ex.example/#reportedBy> (shapeRef <UserShape>))
           (tripleConstraint <http://ex.example/#reportedOn>
            (nodeConstraint datatype <http://www.w3.org/2001/XMLSchema#dateTime>))
           (eachOf
            (tripleConstraint <http://ex.example/#reproducedBy> (shapeRef <EmployeeShape>))
            (tripleConstraint <http://ex.example/#reproducedOn>
             (or
              (nodeConstraint datatype <http://www.w3.org/2001/XMLSchema#dateTime>)
              (nodeConstraint datatype <http://www.w3.org/2001/XMLSchema#date>)) )
            (min 0)
            (max 1))
           (tripleConstraint inverse <http://ex.example/#related>
            (shapeRef <IssueShape>)
            (min 0)
            (max "*")) )
          (extra <http://www.w3.org/1999/02/22-rdf-syntax-ns#type>) closed )
         (shape <UserShape>
          (and
           (nodeConstraint (pattern "^http:/example.org/.*"))
           (eachOf
            (someOf
             (tripleConstraint <http://xmlns.com/foaf/name>
              (nodeConstraint datatype <http://www.w3.org/2001/XMLSchema#string>))
             (eachOf
              (tripleConstraint <http://xmlns.com/foaf/givenName>
               (nodeConstraint datatype <http://www.w3.org/2001/XMLSchema#string>)
               (min 1)
               (max "*"))
              (tripleConstraint <http://xmlns.com/foaf/familyName>
               (nodeConstraint datatype <http://www.w3.org/2001/XMLSchema#string>)) ))
            (tripleConstraint <http://xmlns.com/foaf/mbox> (nodeConstraint iri))) ))
         (shape <EmployeeShape>
          (and
           (eachOf
            (tripleConstraint <http://xmlns.com/foaf/phone> (nodeConstraint iri) (min 0) (max "*"))
            (tripleConstraint <http://xmlns.com/foaf/mbox> (nodeConstraint iri)))
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
             (max 1)) )) ))}
      },
      # Spec FIXME: UserShape needs a predicate
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
         (prefix (("ex" <http://schema.example/>) ("xsd" <http://www.w3.org/2001/XMLSchema#>)))
         (shape <IssueShape>
          (eachOf
           (tripleConstraint <http://schema.example/state>
            (nodeConstraint
             (value <http://schema.example/unassigned>)
             (value <http://schema.example/assigned>)) )
           (tripleConstraint <http://schema.example/reportedBy> (shapeRef <UserShape>))
           (tripleConstraint <http://schema.example/reportedOn>
            (or
             (nodeConstraint datatype <http://www.w3.org/2001/XMLSchema#dateTime>)
             (nodeConstraint datatype <http://www.w3.org/2001/XMLSchema#date>)) )
           (tripleConstraint <http://schema.example/related>
            (shapeRef <IssueShape>)
            (min 0)
            (max "*"))
           (tripleConstraint inverse <http://schema.example/related>
            (shapeRef <IssueShape>)
            (min 0)
            (max "*")) ) closed )
         (shape <UserShape>
          (tripleConstraint a (nodeConstraint (pattern "http://example.org/User#.*")))) )}
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
         (prefix
          (
           ("ex" <http://schema.example/>)
           ("foaf" <http://xmlns.com/foaf/>)
           ("xsd" <http://www.w3.org/2001/XMLSchema#>)
           ("rdf" <http://www.w3.org/1999/02/22-rdf-syntax-ns#>)) )
         (shape <UserShape>
          (eachOf
           (tripleConstraint <http://www.w3.org/1999/02/22-rdf-syntax-ns#type>
            (nodeConstraint (value <http://xmlns.com/foaf/Person>)))
           (tripleConstraint <http://www.w3.org/1999/02/22-rdf-syntax-ns#type>
            (nodeConstraint (value <http://schema.example/User>)))
           (someOf
            (tripleConstraint <http://xmlns.com/foaf/name>
             (nodeConstraint datatype <http://www.w3.org/2001/XMLSchema#string>))
            (eachOf
             (tripleConstraint <http://xmlns.com/foaf/givenName>
              (nodeConstraint datatype <http://www.w3.org/2001/XMLSchema#string>)
              (min 1)
              (max "*"))
             (tripleConstraint <http://xmlns.com/foaf/familyName>
              (nodeConstraint datatype <http://www.w3.org/2001/XMLSchema#string>)) ))
           (tripleConstraint <http://xmlns.com/foaf/mbox> (nodeConstraint iri)))
          (extra <http://www.w3.org/1999/02/22-rdf-syntax-ns#type>
           <http://xmlns.com/foaf/mbox> ) closed ))}
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
         (prefix (("ex" <http://schema.example/>) ("xsd" <http://www.w3.org/2001/XMLSchema#>)))
         (shape <SomeShape>
          (eachOf
           (tripleConstraint <http://schema.example/p>
            (nodeConstraint datatype <http://www.w3.org/2001/XMLSchema#int>)
            (min 0)
            (max "*"))
           (someOf
            (tripleConstraint <http://schema.example/q>
             (nodeConstraint datatype <http://www.w3.org/2001/XMLSchema#int>))
            (tripleConstraint <http://schema.example/r> (nodeConstraint iri))
            (min 0)
            (max 1)) )) )
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
         (prefix (("ex" <http://schema.example/>) ("foaf" <http://xmlns.com/foaf/>)))
         (shape <EmployeeShape>
          (and
           (nodeConstraint (pattern "^http:/example.org/.*"))
           (eachOf
            (tripleConstraint <http://xmlns.com/foaf/phone> (nodeConstraint iri) (min 0) (max "*"))
            (tripleConstraint <http://xmlns.com/foaf/mbox> (nodeConstraint iri)))
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
             (max 1)) )) closed ))}.gsub(/^        /m, '')
      },
      # Spec FIXME: {0;0} should be {0:,}
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
         (prefix (("ex" <http://schema.example/>) ("xsd" <http://www.w3.org/2001/XMLSchema#>)))
         (shape <SomeShape>
          (eachOf
           (tripleConstraint <http://schema.example/p>
            (nodeConstraint datatype <http://www.w3.org/2001/XMLSchema#int>)
            (min 0)
            (max "*"))
           (someOf
            (tripleConstraint <http://schema.example/q>
             (nodeConstraint datatype <http://www.w3.org/2001/XMLSchema#int>)
             (min 0)
             (max 0))
            (tripleConstraint <http://schema.example/r> (nodeConstraint iri))
            (min 0)
            (max 1)) ) closed ))}
      },
    }.each do |name, params|
      it name do
        expect(params[:shexc]).to generate(params[:sxp].gsub(/^        /m, ''))
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
        result: ShEx::ParseError
      },
      "Negated reference 1" => {
        input: %(PREFIX ex: <http://schema.example/> ex:S: NOT @ex:S),
        result: ShEx::ParseError
      },
      "Negated reference 2" => {
        input: %(PREFIX ex: <http://schema.example/> ex:S: NOT @ex:T ex:T @ex:S),
        result: ShEx::ParseError
      },
      "This self-reference on a predicate designated as extra violates the negation requirement:" => {
        input: %(PREFIX ex: <http://schema.example/> ex:S EXTRA ex:p {ex:p @ex:S}),
        result: ShEx::ParseError
      },
      "The same shape with a negated self-reference still violates the negation requirement because the reference occurs with a ShapeNot:" => {
        input: %(PREFIX ex: <http://schema.example/> ex:S EXTRA ex:p {ex:p NOT @ex:S}),
        result: ShEx::ParseError
      },
    }.each do |name, params|
      it name do
        pending("Self Reference validation") if name.include?('self-reference')
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
