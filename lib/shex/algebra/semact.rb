module ShEx::Algebra
  ##
  class SemAct < Operator
    NAME = :semact

    #
    # The evaluation semActsSatisfied on a list of SemActs returns success or failure. The evaluation of an individual SemAct is implementation-dependent.
    def satisfies(n, g, m)
      case operands.first
      when "http://shex.io/extensions/Test/"
      else
        raise NotImpelemented, "unknown SemAct name #{operands.first}"
      end
      operands.select {|o| o.is_a?(Satisfiable)}.all? {|op| op.satisfies(n, g, m)}
    end
  end
end
