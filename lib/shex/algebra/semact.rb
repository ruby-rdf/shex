module ShEx::Algebra
  ##
  class SemAct < Operator
    NAME = :semact

    #
    # The evaluation semActsSatisfied on a list of SemActs returns success or failure. The evaluation of an individual SemAct is implementation-dependent.
    # @param [Array<RDF::Statement>] statements
    # @return [Boolean] `true` if satisfied, `false` if it does not apply
    # @raise [NotSatisfied] if not satisfied
    def satisfies?(statements)
      # FIXME: should have a registry
      case operands.first.to_s
      when "http://shex.io/extensions/Test/"
        md = /^ *(fail|print) *\( *(?:(\"(?:[^\\"]|\\")*\")|([spo])) *\) *$/.match(operands.last.to_s)
        str = md[2] || case md[3]
        when 's' then statements.first.subject
        when 'p' then statements.first.predicate
        when 'o' then statements.first.object
        else          statement.to_ntriples
        end.to_s
        $stdout.puts str
        raise NotSatisfied if md[1] == 'fail'
      else
        raise "unknown SemAct name #{operands.first}"
      end
      true
    end

    # Does This operator is SemAct
    def semact?; true; end
  end
end
