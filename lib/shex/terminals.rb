# -*- encoding: utf-8 -*-
require 'ebnf/ll1/lexer'

module ShEx
  module Terminals
    # Definitions of token regular expressions used for lexical analysis
  
    ##
    # Unicode regular expressions for Ruby 1.9+ with the Oniguruma engine.
    U_CHARS1         = Regexp.compile(<<-EOS.gsub(/\s+/, ''))
                         [\\u00C0-\\u00D6]|[\\u00D8-\\u00F6]|[\\u00F8-\\u02FF]|
                         [\\u0370-\\u037D]|[\\u037F-\\u1FFF]|[\\u200C-\\u200D]|
                         [\\u2070-\\u218F]|[\\u2C00-\\u2FEF]|[\\u3001-\\uD7FF]|
                         [\\uF900-\\uFDCF]|[\\uFDF0-\\uFFFD]|[\\u{10000}-\\u{EFFFF}]
                       EOS
    U_CHARS2         = Regexp.compile("\\u00B7|[\\u0300-\\u036F]|[\\u203F-\\u2040]").freeze
    IRI_RANGE        = Regexp.compile("[[^<>\"{}|^`\\\\]&&[^\\x00-\\x20]]").freeze

    # 87
    UCHAR4               = /\\u([0-9A-Fa-f]{4,4})/.freeze
    UCHAR8               = /\\U([0-9A-Fa-f]{8,8})/.freeze
    UCHAR                = Regexp.union(UCHAR4, UCHAR8).freeze
    # 95
    PERCENT              = /%\h\h/.freeze
    # 97
    PN_LOCAL_ESC         = /\\[_~\.\-\!$\&'\(\)\*\+,;=\/\?\#@%]/.freeze
    # 94
    PLX                  = /#{PERCENT}|#{PN_LOCAL_ESC}/.freeze.freeze
    # 89
    PN_CHARS_BASE        = /[A-Za-z]|#{U_CHARS1}/.freeze
    # 90
    PN_CHARS_U           = /_|#{PN_CHARS_BASE}/.freeze
    # 91
    PN_CHARS             = /[\d-]|#{PN_CHARS_U}|#{U_CHARS2}/.freeze
    PN_LOCAL_BODY        = /(?:(?:\.|:|#{PN_CHARS}|#{PLX})*(?:#{PN_CHARS}|:|#{PLX}))?/.freeze
    PN_CHARS_BODY        = /(?:(?:\.|#{PN_CHARS})*#{PN_CHARS})?/.freeze
    # 92
    PN_PREFIX            = /#{PN_CHARS_BASE}#{PN_CHARS_BODY}/.freeze
    # 93
    PN_LOCAL             = /(?:[\d|]|#{PN_CHARS_U}|#{PLX})#{PN_LOCAL_BODY}/.freeze
    # 82
    EXPONENT             = /[eE][+-]?\d+/
    # 88
    ECHAR                = /\\[tbnrf\\"']/

    WS                   = /(?:\s|(?:#[^\n\r]*))+/m.freeze

    # 71
    RDF_TYPE             = /a/.freeze
    # 72
    IRIREF               = /<(?:#{IRI_RANGE}|#{UCHAR})*>/.freeze
    # 73
    PNAME_NS             = /#{PN_PREFIX}?:/.freeze
    # 74
    PNAME_LN             = /#{PNAME_NS}#{PN_LOCAL}/.freeze
    # 75
    ATPNAME_NS           = /@#{WS}*#{PN_PREFIX}?:/m.freeze
    # 76
    ATPNAME_LN           = /@#{WS}*#{PNAME_NS}#{PN_LOCAL}/m.freeze
    # 77
    BLANK_NODE_LABEL     = /_:(?:\d|#{PN_CHARS_U})(?:(?:#{PN_CHARS}|\.)*#{PN_CHARS})?/.freeze
    # 78
    LANGTAG              = /@[a-zA-Z]+(?:-[a-zA-Z0-9]+)*/.freeze
    # 79
    INTEGER              = /[+-]?\d+/.freeze
    # 80
    DECIMAL              = /[+-]?(?:\d*\.\d+)/.freeze
    # 81
    DOUBLE               = /[+-]?(?:\d+\.\d*#{EXPONENT}|\.?\d+#{EXPONENT})/.freeze
    # 83
    STRING_LITERAL1      = /'(?:[^\'\\\n\r]|#{ECHAR}|#{UCHAR})*'/.freeze
    # 84
    STRING_LITERAL2      = /"(?:[^\"\\\n\r]|#{ECHAR}|#{UCHAR})*"/.freeze
    # 85
    STRING_LITERAL_LONG1 = /'''(?:(?:'|'')?(?:[^'\\]|#{ECHAR}|#{UCHAR}))*'''/m.freeze
    # 86
    STRING_LITERAL_LONG2 = /"""(?:(?:"|"")?(?:[^"\\]|#{ECHAR}|#{UCHAR}))*"""/m.freeze

    # XX
    REGEXP              =  %r(/(?:[^/\\\n\r]|\\[nrt\\|.?*+(){}$-\[\]^/]|#{UCHAR})+/[smix]*).freeze

    # 68
    CODE                 = /\{(?:[^%\\]|\\[%\\]|#{UCHAR})*%#{WS}*\}/m.freeze
    # 70
    REPEAT_RANGE         = /\{\s*#{INTEGER}(?:,#{WS}*(?:#{INTEGER}|\*)?)?#{WS}*\}/.freeze

    # String terminals, mixed case sensitivity
    STR_EXPR = %r(true|false
                 |\^\^|\/\/
                 |[\(\)\{\}\[\],\.;\=\-\~!\|\&\@\$\?\+\*\%\^a]|
                 (?i:OR|AND|NOT
                   |BASE|PREFIX
                   |IRI|BNODE|NONLITERAL
                   |MINLENGTH|MAXLENGTH|LENGTH
                   |MAXINCLUSIVE|MAXEXCLUSIVE
                   |MININCLUSIVE|MINEXCLUSIVE
                   |TOTALDIGITS|FRACTIONDIGITS
                   |START
                   |EXTERNAL|CLOSED|EXTRA|LITERAL
                 )
              )x.freeze

    # Map terminals to canonical form
    STR_MAP = %w{OR AND NOT BASE PREFIX IRI BNODE NONLITERAL
      MINLENGTH MAXLENGTH LENGTH MININCLUSIVE MAXINCLUSIVE MINEXCLUSIVE MAXEXCLUSIVE
      TOTALDIGITS FRACTIONDIGITS START EXTERNAL CLOSED EXTRA LITERAL}.
    inject({}) do |memo, t|
      memo.merge(t.downcase => t)
    end
  
  end
end
