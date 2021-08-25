# This file is automatically generated by ebnf version 2.1.3
# Derived from etc/shex.ebnf
module ShEx::Meta
  RULES = [
    EBNF::Rule.new(:shexDoc, "1", [:seq, :_shexDoc_1, :_shexDoc_2]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_shexDoc_1, "1.1", [:star, :directive]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_shexDoc_2, "1.2", [:opt, :_shexDoc_3]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_shexDoc_3, "1.3", [:seq, :_shexDoc_4, :_shexDoc_5]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_shexDoc_4, "1.4", [:alt, :notStartAction, :startActions]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_shexDoc_5, "1.5", [:star, :statement]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:directive, "2", [:alt, :baseDecl, :prefixDecl]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:baseDecl, "3", [:seq, "BASE", :IRIREF]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:prefixDecl, "4", [:seq, "PREFIX", :PNAME_NS, :IRIREF]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:notStartAction, "5", [:alt, :start, :shapeExprDecl]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:start, "6", [:seq, "START", "=", :_start_1, :_start_2, :_start_3]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_start_1, "6.1", [:opt, "NOT"]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_start_2, "6.2", [:alt, :shapeAtomNoRef, :shapeRef]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_start_3, "6.3", [:opt, :shapeOr]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:startActions, "7", [:plus, :codeDecl]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:statement, "8", [:alt, :directive, :notStartAction]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:shapeExprDecl, "9", [:seq, :shapeExprLabel, :_shapeExprDecl_1]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_shapeExprDecl_1, "9.1", [:alt, :shapeExpression, "EXTERNAL"]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:shapeExpression, "10", [:alt, :_shapeExpression_1, :_shapeExpression_2, :_shapeExpression_3]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_shapeExpression_1, "10.1", [:seq, :_shapeExpression_4, :shapeAtomNoRef, :_shapeExpression_5]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_shapeExpression_4, "10.4", [:opt, "NOT"]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_shapeExpression_5, "10.5", [:opt, :shapeOr]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_shapeExpression_2, "10.2", [:seq, "NOT", :shapeRef, :_shapeExpression_6]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_shapeExpression_6, "10.6", [:opt, :shapeOr]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_shapeExpression_3, "10.3", [:seq, :shapeRef, :shapeOr]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:inlineShapeExpression, "11", [:seq, :inlineShapeOr]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:shapeOr, "12", [:alt, :_shapeOr_1, :_shapeOr_2]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_shapeOr_1, "12.1", [:plus, :_shapeOr_3]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_shapeOr_3, "12.3", [:seq, "OR", :shapeAnd]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_shapeOr_2, "12.2", [:seq, :_shapeOr_4, :_shapeOr_5]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_shapeOr_4, "12.4", [:plus, :_shapeOr_6]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_shapeOr_6, "12.6", [:seq, "AND", :shapeNot]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_shapeOr_5, "12.5", [:star, :_shapeOr_7]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_shapeOr_7, "12.7", [:seq, "OR", :shapeAnd]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:inlineShapeOr, "13", [:seq, :inlineShapeAnd, :_inlineShapeOr_1]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_inlineShapeOr_1, "13.1", [:star, :_inlineShapeOr_2]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_inlineShapeOr_2, "13.2", [:seq, "OR", :inlineShapeAnd]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:shapeAnd, "14", [:seq, :shapeNot, :_shapeAnd_1]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_shapeAnd_1, "14.1", [:star, :_shapeAnd_2]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_shapeAnd_2, "14.2", [:seq, "AND", :shapeNot]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:inlineShapeAnd, "15", [:seq, :inlineShapeNot, :_inlineShapeAnd_1]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_inlineShapeAnd_1, "15.1", [:star, :_inlineShapeAnd_2]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_inlineShapeAnd_2, "15.2", [:seq, "AND", :inlineShapeNot]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:shapeNot, "16", [:seq, :_shapeNot_1, :shapeAtom]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_shapeNot_1, "16.1", [:opt, "NOT"]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:inlineShapeNot, "17", [:seq, :_inlineShapeNot_1, :inlineShapeAtom]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_inlineShapeNot_1, "17.1", [:opt, "NOT"]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:shapeAtom, "18", [:alt, :_shapeAtom_1, :litNodeConstraint, :_shapeAtom_2, :_shapeAtom_3, "."]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_shapeAtom_1, "18.1", [:seq, :nonLitNodeConstraint, :_shapeAtom_4]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_shapeAtom_4, "18.4", [:opt, :shapeOrRef]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_shapeAtom_2, "18.2", [:seq, :shapeOrRef, :_shapeAtom_5]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_shapeAtom_5, "18.5", [:opt, :nonLitNodeConstraint]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_shapeAtom_3, "18.3", [:seq, "(", :shapeExpression, ")"]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:shapeAtomNoRef, "19", [:alt, :_shapeAtomNoRef_1, :litNodeConstraint, :_shapeAtomNoRef_2, :_shapeAtomNoRef_3, "."]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_shapeAtomNoRef_1, "19.1", [:seq, :nonLitNodeConstraint, :_shapeAtomNoRef_4]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_shapeAtomNoRef_4, "19.4", [:opt, :shapeOrRef]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_shapeAtomNoRef_2, "19.2", [:seq, :shapeDefinition, :_shapeAtomNoRef_5]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_shapeAtomNoRef_5, "19.5", [:opt, :nonLitNodeConstraint]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_shapeAtomNoRef_3, "19.3", [:seq, "(", :shapeExpression, ")"]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:inlineShapeAtom, "20", [:alt, :_inlineShapeAtom_1, :litNodeConstraint, :_inlineShapeAtom_2, :_inlineShapeAtom_3, "."]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_inlineShapeAtom_1, "20.1", [:seq, :nonLitNodeConstraint, :_inlineShapeAtom_4]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_inlineShapeAtom_4, "20.4", [:opt, :inlineShapeOrRef]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_inlineShapeAtom_2, "20.2", [:seq, :inlineShapeOrRef, :_inlineShapeAtom_5]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_inlineShapeAtom_5, "20.5", [:opt, :nonLitNodeConstraint]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_inlineShapeAtom_3, "20.3", [:seq, "(", :shapeExpression, ")"]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:shapeOrRef, "21", [:alt, :shapeDefinition, :shapeRef]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:inlineShapeOrRef, "22", [:alt, :inlineShapeDefinition, :shapeRef]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:shapeRef, "23", [:alt, :ATPNAME_LN, :ATPNAME_NS, :_shapeRef_1]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_shapeRef_1, "23.1", [:seq, "@", :shapeExprLabel]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:litNodeConstraint, "24", [:alt, :_litNodeConstraint_1, :_litNodeConstraint_2, :_litNodeConstraint_3, :_litNodeConstraint_4, :_litNodeConstraint_5]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_litNodeConstraint_1, "24.1", [:seq, "LITERAL", :_litNodeConstraint_6]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_litNodeConstraint_6, "24.6", [:star, :xsFacet]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_litNodeConstraint_2, "24.2", [:seq, :nonLiteralKind, :_litNodeConstraint_7]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_litNodeConstraint_7, "24.7", [:star, :stringFacet]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_litNodeConstraint_3, "24.3", [:seq, :datatype, :_litNodeConstraint_8]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_litNodeConstraint_8, "24.8", [:star, :xsFacet]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_litNodeConstraint_4, "24.4", [:seq, :valueSet, :_litNodeConstraint_9]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_litNodeConstraint_9, "24.9", [:star, :xsFacet]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_litNodeConstraint_5, "24.5", [:plus, :numericFacet]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:nonLitNodeConstraint, "25", [:alt, :_nonLitNodeConstraint_1, :_nonLitNodeConstraint_2]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_nonLitNodeConstraint_1, "25.1", [:seq, :nonLiteralKind, :_nonLitNodeConstraint_3]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_nonLitNodeConstraint_3, "25.3", [:star, :stringFacet]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_nonLitNodeConstraint_2, "25.2", [:plus, :stringFacet]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:nonLiteralKind, "26", [:alt, "IRI", "BNODE", "NONLITERAL"]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:xsFacet, "27", [:alt, :stringFacet, :numericFacet]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:stringFacet, "28", [:alt, :_stringFacet_1, :REGEXP]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_stringFacet_1, "28.1", [:seq, :stringLength, :INTEGER]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:stringLength, "29", [:alt, "LENGTH", "MINLENGTH", "MAXLENGTH"]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:numericFacet, "30", [:alt, :_numericFacet_1, :_numericFacet_2]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_numericFacet_1, "30.1", [:seq, :numericRange, :numericLiteral]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_numericFacet_2, "30.2", [:seq, :numericLength, :INTEGER]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:numericRange, "31", [:alt, "MININCLUSIVE", "MINEXCLUSIVE", "MAXINCLUSIVE", "MAXEXCLUSIVE"]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:numericLength, "32", [:alt, "TOTALDIGITS", "FRACTIONDIGITS"]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:shapeDefinition, "33", [:seq, :_shapeDefinition_1, "{", :_shapeDefinition_2, "}", :_shapeDefinition_3, :semanticActions]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_shapeDefinition_1, "33.1", [:star, :_shapeDefinition_4]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_shapeDefinition_4, "33.4", [:alt, :extraPropertySet, "CLOSED"]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_shapeDefinition_2, "33.2", [:opt, :tripleExpression]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_shapeDefinition_3, "33.3", [:star, :annotation]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:inlineShapeDefinition, "34", [:seq, :_inlineShapeDefinition_1, "{", :_inlineShapeDefinition_2, "}"]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_inlineShapeDefinition_1, "34.1", [:star, :_inlineShapeDefinition_3]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_inlineShapeDefinition_3, "34.3", [:alt, :extraPropertySet, "CLOSED"]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_inlineShapeDefinition_2, "34.2", [:opt, :tripleExpression]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:extraPropertySet, "35", [:seq, "EXTRA", :_extraPropertySet_1]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_extraPropertySet_1, "35.1", [:plus, :predicate]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:tripleExpression, "36", [:seq, :oneOfTripleExpr]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:oneOfTripleExpr, "37", [:seq, :groupTripleExpr, :_oneOfTripleExpr_1]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_oneOfTripleExpr_1, "37.1", [:star, :_oneOfTripleExpr_2]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_oneOfTripleExpr_2, "37.2", [:seq, "|", :groupTripleExpr]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:groupTripleExpr, "40", [:seq, :unaryTripleExpr, :_groupTripleExpr_1]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_groupTripleExpr_1, "40.1", [:star, :_groupTripleExpr_2]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_groupTripleExpr_2, "40.2", [:seq, ";", :_groupTripleExpr_3]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_groupTripleExpr_3, "40.3", [:opt, :unaryTripleExpr]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:unaryTripleExpr, "43", [:alt, :_unaryTripleExpr_1, :include]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_unaryTripleExpr_1, "43.1", [:seq, :_unaryTripleExpr_2, :_unaryTripleExpr_3]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_unaryTripleExpr_2, "43.2", [:opt, :productionLabel]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_unaryTripleExpr_3, "43.3", [:alt, :tripleConstraint, :bracketedTripleExpr]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:productionLabel, "43a", [:seq, "$", :_productionLabel_1]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_productionLabel_1, "43a.1", [:alt, :iri, :blankNode]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:bracketedTripleExpr, "44", [:seq, "(", :oneOfTripleExpr, ")", :_bracketedTripleExpr_1, :_bracketedTripleExpr_2, :semanticActions]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_bracketedTripleExpr_1, "44.1", [:opt, :cardinality]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_bracketedTripleExpr_2, "44.2", [:star, :annotation]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:tripleConstraint, "45", [:seq, :_tripleConstraint_1, :predicate, :inlineShapeExpression, :_tripleConstraint_2, :_tripleConstraint_3, :semanticActions]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_tripleConstraint_1, "45.1", [:opt, :senseFlags]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_tripleConstraint_2, "45.2", [:opt, :cardinality]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_tripleConstraint_3, "45.3", [:star, :annotation]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:cardinality, "46", [:alt, "*", "+", "?", :REPEAT_RANGE]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:senseFlags, "47", [:seq, "^"]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:valueSet, "48", [:seq, "[", :_valueSet_1, "]"]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_valueSet_1, "48.1", [:star, :valueSetValue]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:valueSetValue, "49", [:alt, :iriRange, :literalRange, :languageRange, :_valueSetValue_1]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_valueSetValue_1, "49.1", [:seq, ".", :_valueSetValue_2]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_valueSetValue_2, "49.2", [:plus, :exclusion]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:exclusion, "50", [:seq, "-", :_exclusion_1, :_exclusion_2]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_exclusion_1, "50.1", [:alt, :iri, :literal, :LANGTAG]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_exclusion_2, "50.2", [:opt, "~"]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:iriRange, "51", [:seq, :iri, :_iriRange_1]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_iriRange_1, "51.1", [:opt, :_iriRange_2]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_iriRange_2, "51.2", [:seq, "~", :_iriRange_3]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_iriRange_3, "51.3", [:star, :iriExclusion]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:iriExclusion, "52", [:seq, "-", :iri, :_iriExclusion_1]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_iriExclusion_1, "52.1", [:opt, "~"]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:literalRange, "53", [:seq, :literal, :_literalRange_1]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_literalRange_1, "53.1", [:opt, :_literalRange_2]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_literalRange_2, "53.2", [:seq, "~", :_literalRange_3]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_literalRange_3, "53.3", [:star, :literalExclusion]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:literalExclusion, "54", [:seq, "-", :literal, :_literalExclusion_1]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_literalExclusion_1, "54.1", [:opt, "~"]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:languageRange, "55", [:seq, :LANGTAG, :_languageRange_1]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_languageRange_1, "55.1", [:opt, :_languageRange_2]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_languageRange_2, "55.2", [:seq, "~", :_languageRange_3]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_languageRange_3, "55.3", [:star, :languageExclusion]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:languageExclusion, "56", [:seq, "-", :LANGTAG, :_languageExclusion_1]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_languageExclusion_1, "56.1", [:opt, "~"]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:include, "57", [:seq, "&", :tripleExprLabel]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:annotation, "58", [:seq, "//", :predicate, :_annotation_1]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_annotation_1, "58.1", [:alt, :iri, :literal]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:semanticActions, "59", [:star, :codeDecl]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:codeDecl, "60", [:seq, "%", :iri, :_codeDecl_1]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_codeDecl_1, "60.1", [:alt, :CODE, "%"]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:literal, "13t", [:alt, :rdfLiteral, :numericLiteral, :booleanLiteral]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:predicate, "61", [:alt, :iri, :RDF_TYPE]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:datatype, "62", [:seq, :iri]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:shapeExprLabel, "63", [:alt, :iri, :blankNode]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:tripleExprLabel, "64", [:alt, :iri, :blankNode]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:numericLiteral, "16t", [:alt, :DOUBLE, :DECIMAL, :INTEGER]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:rdfLiteral, "65", [:alt, :langString, :_rdfLiteral_1]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_rdfLiteral_1, "65.1", [:seq, :string, :_rdfLiteral_2]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_rdfLiteral_2, "65.2", [:opt, :_rdfLiteral_3]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_rdfLiteral_3, "65.3", [:seq, "^^", :datatype]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:booleanLiteral, "134s", [:alt, "true", "false"]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:string, "135s", [:alt, :STRING_LITERAL_LONG1, :STRING_LITERAL_LONG2, :STRING_LITERAL1, :STRING_LITERAL2]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:langString, "66", [:alt, :LANG_STRING_LITERAL1, :LANG_STRING_LITERAL_LONG1, :LANG_STRING_LITERAL2, :LANG_STRING_LITERAL_LONG2]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:iri, "136s", [:alt, :IRIREF, :prefixedName]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:prefixedName, "137s", [:alt, :PNAME_LN, :PNAME_NS]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:blankNode, "138s", [:seq, :BLANK_NODE_LABEL]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_terminals, nil, [:seq], kind: :terminals).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:CODE, "67", [:seq, "{", :_CODE_1], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_CODE_1, "67.1", [:range, "^%\\] | '\\'[%\\] | UCHAR)* '%''}'"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:REPEAT_RANGE, "68", [:seq, "{", :INTEGER, :_REPEAT_RANGE_1, "}"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_REPEAT_RANGE_1, "68.1", [:opt, :_REPEAT_RANGE_2], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_REPEAT_RANGE_2, "68.2", [:seq, ",", :_REPEAT_RANGE_3], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_REPEAT_RANGE_3, "68.3", [:opt, :_REPEAT_RANGE_4], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_REPEAT_RANGE_4, "68.4", [:alt, :INTEGER, "*"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:RDF_TYPE, "69", [:seq, "a"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:IRIREF, "18t", [:seq, "<", :_IRIREF_1], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_IRIREF_1, "18t.1", [:range, "^#x00-#x20<>\"{}|^`\\] | UCHAR)* '>' /* #x00=NULL #01-#x1F=control codes #x20=space */"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:PNAME_NS, "140s", [:seq, :_PNAME_NS_1, ":"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_PNAME_NS_1, "140s.1", [:opt, :PN_PREFIX], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:PNAME_LN, "141s", [:seq, :PNAME_NS, :PN_LOCAL], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:ATPNAME_NS, "70", [:seq, "@", :_ATPNAME_NS_1, ":"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_ATPNAME_NS_1, "70.1", [:opt, :PN_PREFIX], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:ATPNAME_LN, "71", [:seq, "@", :PNAME_NS, :PN_LOCAL], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:REGEXP, "72", [:seq, "/", :_REGEXP_1, "/", :_REGEXP_2], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_REGEXP_1, "72.1", [:plus, :_REGEXP_3], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_REGEXP_3, "72.3", [:alt, :_REGEXP_4, :_REGEXP_5, :UCHAR], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_REGEXP_4, "72.4", [:range, "^/\\\n\r"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_REGEXP_5, "72.5", [:seq, "\\", :_REGEXP_6], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_REGEXP_6, "72.6", [:range, "nrt\\|.?*+(){}$-[]^/"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_REGEXP_2, "72.2", [:star, :_REGEXP_7], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_REGEXP_7, "72.7", [:range, "smix"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:BLANK_NODE_LABEL, "142s", [:seq, "_:", :_BLANK_NODE_LABEL_1, :_BLANK_NODE_LABEL_2], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_BLANK_NODE_LABEL_1, "142s.1", [:alt, :PN_CHARS_U, :_BLANK_NODE_LABEL_3], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_BLANK_NODE_LABEL_3, "142s.3", [:range, "0-9"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_BLANK_NODE_LABEL_2, "142s.2", [:opt, :_BLANK_NODE_LABEL_4], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_BLANK_NODE_LABEL_4, "142s.4", [:seq, :_BLANK_NODE_LABEL_5, :PN_CHARS], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_BLANK_NODE_LABEL_5, "142s.5", [:star, :_BLANK_NODE_LABEL_6], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_BLANK_NODE_LABEL_6, "142s.6", [:alt, :PN_CHARS, "."], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:LANGTAG, "145s", [:seq, "@", :_LANGTAG_1, :_LANGTAG_2], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_LANGTAG_1, "145s.1", [:plus, :_LANGTAG_3], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_LANGTAG_3, "145s.3", [:range, "a-zA-Z"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_LANGTAG_2, "145s.2", [:star, :_LANGTAG_4], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_LANGTAG_4, "145s.4", [:seq, "-", :_LANGTAG_5], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_LANGTAG_5, "145s.5", [:plus, :_LANGTAG_6], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_LANGTAG_6, "145s.6", [:range, "a-zA-Z0-9"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:INTEGER, "19t", [:seq, :_INTEGER_1, :_INTEGER_2], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_INTEGER_1, "19t.1", [:opt, :_INTEGER_3], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_INTEGER_3, "19t.3", [:range, "+-"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_INTEGER_2, "19t.2", [:plus, :_INTEGER_4], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_INTEGER_4, "19t.4", [:range, "0-9"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:DECIMAL, "20t", [:seq, :_DECIMAL_1, :_DECIMAL_2, ".", :_DECIMAL_3], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_DECIMAL_1, "20t.1", [:opt, :_DECIMAL_4], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_DECIMAL_4, "20t.4", [:range, "+-"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_DECIMAL_2, "20t.2", [:star, :_DECIMAL_5], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_DECIMAL_5, "20t.5", [:range, "0-9"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_DECIMAL_3, "20t.3", [:plus, :_DECIMAL_6], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_DECIMAL_6, "20t.6", [:range, "0-9"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:DOUBLE, "21t", [:seq, :_DOUBLE_1, :_DOUBLE_2], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_DOUBLE_1, "21t.1", [:opt, :_DOUBLE_3], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_DOUBLE_3, "21t.3", [:range, "+-"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_DOUBLE_2, "21t.2", [:alt, :_DOUBLE_4, :_DOUBLE_5], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_DOUBLE_4, "21t.4", [:seq, :_DOUBLE_6, ".", :_DOUBLE_7, :EXPONENT], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_DOUBLE_6, "21t.6", [:plus, :_DOUBLE_8], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_DOUBLE_8, "21t.8", [:range, "0-9"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_DOUBLE_7, "21t.7", [:star, :_DOUBLE_9], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_DOUBLE_9, "21t.9", [:range, "0-9"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_DOUBLE_5, "21t.5", [:seq, :_DOUBLE_10, :_DOUBLE_11, :EXPONENT], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_DOUBLE_10, "21t.10", [:opt, "."], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_DOUBLE_11, "21t.11", [:plus, :_DOUBLE_12], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_DOUBLE_12, "21t.12", [:range, "0-9"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:EXPONENT, "155s", [:seq, :_EXPONENT_1, :_EXPONENT_2, :_EXPONENT_3], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_EXPONENT_1, "155s.1", [:range, "eE"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_EXPONENT_2, "155s.2", [:opt, :_EXPONENT_4], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_EXPONENT_4, "155s.4", [:range, "+-"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_EXPONENT_3, "155s.3", [:plus, :_EXPONENT_5], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_EXPONENT_5, "155s.5", [:range, "0-9"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:STRING_LITERAL1, "156s", [:seq, "'", :_STRING_LITERAL1_1, "'"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_STRING_LITERAL1_1, "156s.1", [:star, :_STRING_LITERAL1_2], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_STRING_LITERAL1_2, "156s.2", [:alt, :_STRING_LITERAL1_3, :ECHAR, :UCHAR], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_STRING_LITERAL1_3, "156s.3", [:range, "^#x27#x5C#xA#xD"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:STRING_LITERAL2, "157s", [:seq, "\"", :_STRING_LITERAL2_1, "\""], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_STRING_LITERAL2_1, "157s.1", [:star, :_STRING_LITERAL2_2], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_STRING_LITERAL2_2, "157s.2", [:alt, :_STRING_LITERAL2_3, :ECHAR, :UCHAR], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_STRING_LITERAL2_3, "157s.3", [:range, "^#x22#x5C#xA#xD"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:STRING_LITERAL_LONG1, "158s", [:seq, "'''", :_STRING_LITERAL_LONG1_1], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_STRING_LITERAL_LONG1_1, "158s.1", [:seq, :_STRING_LITERAL_LONG1_2, :_STRING_LITERAL_LONG1_3], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_STRING_LITERAL_LONG1_2, "158s.2", [:opt, :_STRING_LITERAL_LONG1_4], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_STRING_LITERAL_LONG1_4, "158s.4", [:alt, "'", "''"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_STRING_LITERAL_LONG1_3, "158s.3", [:range, "^'\\] | ECHAR | UCHAR))* \"'''\""], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:STRING_LITERAL_LONG2, "159s", [:seq, "\"\"\"", :_STRING_LITERAL_LONG2_1], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_STRING_LITERAL_LONG2_1, "159s.1", [:seq, :_STRING_LITERAL_LONG2_2, :_STRING_LITERAL_LONG2_3], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_STRING_LITERAL_LONG2_2, "159s.2", [:opt, :_STRING_LITERAL_LONG2_4], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_STRING_LITERAL_LONG2_4, "159s.4", [:alt, "\"", "\"\""], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_STRING_LITERAL_LONG2_3, "159s.3", [:range, "^\"\\] | ECHAR | UCHAR))* '\"\"\"'"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:LANG_STRING_LITERAL1, "73", [:seq, "'", :_LANG_STRING_LITERAL1_1, "'", :LANGTAG], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_LANG_STRING_LITERAL1_1, "73.1", [:star, :_LANG_STRING_LITERAL1_2], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_LANG_STRING_LITERAL1_2, "73.2", [:alt, :_LANG_STRING_LITERAL1_3, :ECHAR, :UCHAR], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_LANG_STRING_LITERAL1_3, "73.3", [:range, "^#x27#x5C#xA#xD"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:LANG_STRING_LITERAL2, "74", [:seq, "\"", :_LANG_STRING_LITERAL2_1, "\"", :LANGTAG], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_LANG_STRING_LITERAL2_1, "74.1", [:star, :_LANG_STRING_LITERAL2_2], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_LANG_STRING_LITERAL2_2, "74.2", [:alt, :_LANG_STRING_LITERAL2_3, :ECHAR, :UCHAR], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_LANG_STRING_LITERAL2_3, "74.3", [:range, "^#x22#x5C#xA#xD"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:LANG_STRING_LITERAL_LONG1, "75", [:seq, "'''", :_LANG_STRING_LITERAL_LONG1_1], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_LANG_STRING_LITERAL_LONG1_1, "75.1", [:seq, :_LANG_STRING_LITERAL_LONG1_2, :_LANG_STRING_LITERAL_LONG1_3], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_LANG_STRING_LITERAL_LONG1_2, "75.2", [:opt, :_LANG_STRING_LITERAL_LONG1_4], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_LANG_STRING_LITERAL_LONG1_4, "75.4", [:alt, "'", "''"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_LANG_STRING_LITERAL_LONG1_3, "75.3", [:range, "^'\\] | ECHAR | UCHAR))* \"'''\" LANGTAG"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:LANG_STRING_LITERAL_LONG2, "76", [:seq, "\"\"\"", :_LANG_STRING_LITERAL_LONG2_1], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_LANG_STRING_LITERAL_LONG2_1, "76.1", [:seq, :_LANG_STRING_LITERAL_LONG2_2, :_LANG_STRING_LITERAL_LONG2_3], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_LANG_STRING_LITERAL_LONG2_2, "76.2", [:opt, :_LANG_STRING_LITERAL_LONG2_4], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_LANG_STRING_LITERAL_LONG2_4, "76.4", [:alt, "\"", "\"\""], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_LANG_STRING_LITERAL_LONG2_3, "76.3", [:range, "^\"\\] | ECHAR | UCHAR))* '\"\"\"' LANGTAG"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:UCHAR, "26t", [:alt, :_UCHAR_1, :_UCHAR_2], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_UCHAR_1, "26t.1", [:seq, "\\u", :HEX, :HEX, :HEX, :HEX], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_UCHAR_2, "26t.2", [:seq, "\\U", :HEX, :HEX, :HEX, :HEX, :HEX, :HEX, :HEX, :HEX], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:ECHAR, "160s", [:seq, "\\", :_ECHAR_1], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_ECHAR_1, "160s.1", [:range, "tbnrf\\\"'"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:PN_CHARS_BASE, "164s", [:alt, :_PN_CHARS_BASE_1, :_PN_CHARS_BASE_2, :_PN_CHARS_BASE_3, :_PN_CHARS_BASE_4, :_PN_CHARS_BASE_5, :_PN_CHARS_BASE_6, :_PN_CHARS_BASE_7, :_PN_CHARS_BASE_8, :_PN_CHARS_BASE_9, :_PN_CHARS_BASE_10, :_PN_CHARS_BASE_11, :_PN_CHARS_BASE_12, :_PN_CHARS_BASE_13, :_PN_CHARS_BASE_14], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_PN_CHARS_BASE_1, "164s.1", [:range, "A-Z"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_PN_CHARS_BASE_2, "164s.2", [:range, "a-z"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_PN_CHARS_BASE_3, "164s.3", [:range, "#x00C0-#x00D6"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_PN_CHARS_BASE_4, "164s.4", [:range, "#x00D8-#x00F6"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_PN_CHARS_BASE_5, "164s.5", [:range, "#x00F8-#x02FF"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_PN_CHARS_BASE_6, "164s.6", [:range, "#x0370-#x037D"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_PN_CHARS_BASE_7, "164s.7", [:range, "#x037F-#x1FFF"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_PN_CHARS_BASE_8, "164s.8", [:range, "#x200C-#x200D"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_PN_CHARS_BASE_9, "164s.9", [:range, "#x2070-#x218F"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_PN_CHARS_BASE_10, "164s.10", [:range, "#x2C00-#x2FEF"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_PN_CHARS_BASE_11, "164s.11", [:range, "#x3001-#xD7FF"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_PN_CHARS_BASE_12, "164s.12", [:range, "#xF900-#xFDCF"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_PN_CHARS_BASE_13, "164s.13", [:range, "#xFDF0-#xFFFD"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_PN_CHARS_BASE_14, "164s.14", [:range, "#x10000-#xEFFFF"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:PN_CHARS_U, "165s", [:alt, :PN_CHARS_BASE, "_"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:PN_CHARS, "167s", [:alt, :PN_CHARS_U, "-", :_PN_CHARS_1, :_PN_CHARS_2, :_PN_CHARS_3, :_PN_CHARS_4], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_PN_CHARS_1, "167s.1", [:range, "0-9"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_PN_CHARS_2, "167s.2", [:range, "#x00B7"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_PN_CHARS_3, "167s.3", [:range, "#x0300-#x036F"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_PN_CHARS_4, "167s.4", [:range, "#x203F-#x2040"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:PN_PREFIX, "168s", [:seq, :PN_CHARS_BASE, :_PN_PREFIX_1], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_PN_PREFIX_1, "168s.1", [:opt, :_PN_PREFIX_2], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_PN_PREFIX_2, "168s.2", [:seq, :_PN_PREFIX_3, :PN_CHARS], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_PN_PREFIX_3, "168s.3", [:star, :_PN_PREFIX_4], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_PN_PREFIX_4, "168s.4", [:alt, :PN_CHARS, "."], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:PN_LOCAL, "169s", [:seq, :_PN_LOCAL_1, :_PN_LOCAL_2], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_PN_LOCAL_1, "169s.1", [:alt, :PN_CHARS_U, ":", :_PN_LOCAL_3, :PLX], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_PN_LOCAL_3, "169s.3", [:range, "0-9"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_PN_LOCAL_2, "169s.2", [:opt, :_PN_LOCAL_4], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_PN_LOCAL_4, "169s.4", [:seq, :_PN_LOCAL_5, :_PN_LOCAL_6], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_PN_LOCAL_5, "169s.5", [:star, :_PN_LOCAL_7], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_PN_LOCAL_7, "169s.7", [:alt, :PN_CHARS, ".", ":", :PLX], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_PN_LOCAL_6, "169s.6", [:alt, :PN_CHARS, ":", :PLX], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:PLX, "170s", [:alt, :PERCENT, :PN_LOCAL_ESC], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:PERCENT, "171s", [:seq, "%", :HEX, :HEX], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:HEX, "172s", [:alt, :_HEX_1, :_HEX_2, :_HEX_3], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_HEX_1, "172s.1", [:range, "0-9"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_HEX_2, "172s.2", [:range, "A-F"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_HEX_3, "172s.3", [:range, "a-f"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:PN_LOCAL_ESC, "173s", [:seq, "\\", :_PN_LOCAL_ESC_1], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_PN_LOCAL_ESC_1, "173s.1", [:alt, "_", "~", ".", "-", "!", "$", "&", "'", "(", ")", "*", "+", ",", ";", "=", "/", "?", "#", "@", "%"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:_pass, nil, [:alt, :__pass_1, :__pass_2], kind: :pass).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:__pass_1, nil, [:plus, :__pass_3]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:__pass_3, nil, [:range, " \t\r\n"], kind: :terminal).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:__pass_2, nil, [:seq, "#", :__pass_4]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:__pass_4, nil, [:star, :__pass_5]).extend(EBNF::PEG::Rule),
    EBNF::Rule.new(:__pass_5, nil, [:range, "^\r\n"], kind: :terminal).extend(EBNF::PEG::Rule),
  ]
end

