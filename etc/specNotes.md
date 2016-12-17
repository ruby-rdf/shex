## 4.2 Mapping from Nodes to Shapes

* The description of `ShapeMap` should clarify that the node in the map represents a node within the graph being satisfied, not a label within the schema. The distinction between a `shapeLabel` and a `node` in a graph can be elusive.
* The use of BNodes for identifying nodes in a graph is not conformant with the meaning of a blank node in RDF Concepts. Even though some systems may allow you to get a node within a graph using the bnode label contained within a serialization from which the graph is created, this is problematic. It may be better to identify nodes in a `ShapeMap` using something like a [SPARQL Property Path](https://www.w3.org/TR/sparql11-query/#propertypath-syntaxforms) or [Path Expression](https://www.w3.org/TR/ldpatch/#path-expression) as defined in [LD Patch](https://www.w3.org/TR/ldpatch/). For example:

  ```
  {
      "http://inst.example/#Issue1": "http://schema.example/IssueShape,
      "http://inst.example/#Issue1 / http://ex.example/#reportedBy", "_:UserShape",
      "http://inst.example/#Issue1 / http://ex.example/#reportedBy", "http://schema.example/EmployeeShape"
  }
  ```

  This might instead borrow syntax from ShExC, but that won't help much for ShExJ.

## 4.3.2 Semantics (Shape Expressions)

* `S` is used consistently in describing how `satisfies` operates, but it is not defined what `S` represents. Presumably this is `se` from `satisfies(n, se, G, m)`.
* Presumably, `satisfies` also requires that the shape schema be used, as it is required for looking up shape references. Perhaps the schema is intended to be in scope.
* It should be clarified that `n` represents a node in `G`, and also a key in `m`. And that `se` represents a Shape Expression identified by the value of `n` in `m`.
* `S is a Shape and satisfies(n, se) as defined below in Shapes and Triple Expressions.` Note that `satisfies` here takes just two arguments, but elsewhere, and in the reference, it takes four arguments.

## 4.4.1 Semantics (Node Constraints)
* `satisfies2(n, nc)` takes two arguments. This is fine if it reads that `n` is the object of some triple, for which the constraint is checked (`G` may still be necessary, though). However, the _NODE KIND EXMPLE 1_ uses `issue1`, `issue2`, and `issue3`, which are subjects, and clearly the `IRI` constraint is checked on the object of the triples. It seems that the semantics of _TripleConstraint_ might handle this, but it's not clear how this works, as `value` is not in `m` in that description.

## 4.4.3 Datatype Constraints
* shape should use `xsd:date`, not `xsd:dateTime`. (In PR)

### 4.4.6 Values Constraint
* Example 2 data `<mailto:sales-contactus-999@a.example>` should be `<mailto:sales-contacts-999@a.example>` to be false. (in PR)
* Also, note that **VALUES CONSTRAINT EXAMPLE 2** appears later in **6. Parsing ShEx Compact syntax** as a totally different shape.

## 4.5 Shapes and Triple Expressions
* Shape looks like there is zero or one extra IRI, but grammar has `predicate+`
* Description of `expr is a TripleConstraint`:
  * uses `givenName` and `author`, should both be `givenName`.
  * use `value` instead of `n2`?
* What is Shape has an expression with cardinality 0; in this case, it would be an error if `matched` was not empty. But, this might not happen unless cardinality is specified on the shape itself.

## 4.6.1 Inclusion Requiement
* ShExJ version of example should use `EachOf` instead of `ShapeAnd`, as it's wrapped in `Shape`.
## 4.7 Semantic Actions
* Shape uses `ex:p1`, but data uses `<http://a.example/p1>`.
* What do to for Test action with no argument?

## 4.9.1 Simple Examples (Validation Examples)
* The third example fails because `nonmatchables` includes `<Alice> ex:shoeSize 30 .`
* The third example also incorrectly places `extra` inside of TripleConstraint.