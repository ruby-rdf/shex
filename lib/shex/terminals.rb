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

    # 26t
    UCHAR                = EBNF::LL1::Lexer::UCHAR
    # 171s
    PERCENT              = /%[0-9A-Fa-f]{2}/.freeze
    # 173s
    PN_LOCAL_ESC         = /\\[_~\.\-\!$\&'\(\)\*\+,;=\/\?\#@%]/.freeze
    # 170s
    PLX                  = /#{PERCENT}|#{PN_LOCAL_ESC}/.freeze.freeze
    # 164s
    PN_CHARS_BASE        = /[A-Z]|[a-z]|#{U_CHARS1}/.freeze
    # 165s
    PN_CHARS_U           = /_|#{PN_CHARS_BASE}/.freeze
    # 167s
    PN_CHARS             = /-|[0-9]|#{PN_CHARS_U}|#{U_CHARS2}/.freeze
    PN_LOCAL_BODY        = /(?:(?:\.|:|#{PN_CHARS}|#{PLX})*(?:#{PN_CHARS}|:|#{PLX}))?/.freeze
    PN_CHARS_BODY        = /(?:(?:\.|#{PN_CHARS})*#{PN_CHARS})?/.freeze
    # 168s
    PN_PREFIX            = /#{PN_CHARS_BASE}#{PN_CHARS_BODY}/.freeze
    # 169s
    PN_LOCAL             = /(?:[0-9]|:|#{PN_CHARS_U}|#{PLX})#{PN_LOCAL_BODY}/.freeze
    # 155s
    EXPONENT             = /[eE][+-]?[0-9]+/
    # 160s
    ECHAR                = /\\[tbnrf\\"']/
    # 79
    WS                   = /(?:\s|(?:#[^\n\r]*))+/m.freeze

    # 3y
    RDF_TYPE             = /a/.freeze
    # 18t
    IRIREF               = /<(?:#{IRI_RANGE}|#{UCHAR})*>/.freeze
    # 140s
    PNAME_NS             = /#{PN_PREFIX}?:/.freeze
    # 141s
    PNAME_LN             = /@#{PNAME_NS}#{PN_LOCAL}/.freeze
    # 140x
    ATPNAME_NS           = /@#{PN_PREFIX}?:/.freeze
    # 141x
    ATPNAME_LN           = /#{PNAME_NS}#{PN_LOCAL}/.freeze
    # 142s
    BLANK_NODE_LABEL     = /_:(?:[0-9]|#{PN_CHARS_U})(?:(?:#{PN_CHARS}|\.)*#{PN_CHARS})?/.freeze
    # 145s
    LANGTAG              = /@[a-zA-Z]+(?:-[a-zA-Z0-9]+)*/.freeze
    # 19t
    INTEGER              = /[+-]?[0-9]+/.freeze
    # 20t
    DECIMAL              = /[+-]?(?:[0-9]*\.[0-9]+)/.freeze
    # 21t
    DOUBLE               = /[+-]?(?:[0-9]+\.[0-9]*#{EXPONENT}|\.?[0-9]+#{EXPONENT})/.freeze
    # 156s
    STRING_LITERAL1      = /'(?:[^\'\\\n\r]|#{ECHAR}|#{UCHAR})*'/.freeze
    # 157s
    STRING_LITERAL2      = /"(?:[^\"\\\n\r]|#{ECHAR}|#{UCHAR})*"/.freeze
    # 158s
    STRING_LITERAL_LONG1 = /'''(?:(?:'|'')?(?:[^'\\]|#{ECHAR}|#{UCHAR}))*'''/m.freeze
    # 159s
    STRING_LITERAL_LONG2 = /"""(?:(?:"|"")?(?:[^"\\]|#{ECHAR}|#{UCHAR}))*"""/m.freeze
    # 163s
    ANON                 = /\[#{WS}*\]/m.freeze

    # 29
    CODE                 = /\{(?:[^%\\]|\\[%\\]|#{UCHAR})*%#{WS}*\}/.freeze
    # 30
    REPEAT_RANGE         = /\{#{WS}*#{INTEGER}(?:,#{WS}*(?:#{INTEGER}|\*)?)?#{WS}*\}/.freeze

    # String terminals, case sensitive
    STR_EXPR = %r(true|false
                 |\^\^|\/\/
                 |[\(\),.;\{\}\=\-\~!\|\&\@\$^\/a]
              )x.freeze

    # String terminals, case insensitive
    MC_EXPR = %r(OR|AND|NOT
                 |BASE|PREFIX
                 |IRI|BNODE|NONLITERAL|PATTERN
                 |MINLENGTH|MAXLENGTH|LENGTH
                 |MAXINCLUSIVE|MAXEXCLUSIVE
                 |MININCLUSIVE|MINEXCLUSIVE
                 |TOTALDIGITS|FRACTIONDIGITS
                 |start
                 |EXTERNAL|CLOSED|EXTRA|LITERAL
              )xi.freeze

    # Map terminals to canonical form
    MC_MAP = %w{OR AND NOT BASE PREFIX IRI BNODE NONLITERAL PATTERN
      MINLENGTH MAXLENGTH LENGTH MININCLUSIVE MAXINCLUSIVE MINEXCLUSIVE MAXEXCLUSIVE
      TOTALDIGITS FRACTIONDIGITS START EXTERNAL CLOSED EXTRA LITERAL}.
    inject({}) do |memo, t|
      memo.merge(t.downcase => t)
    end
  
  end
end
