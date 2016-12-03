module ShEx::Algebra
  ##
  class Or < Operator
    NAME = :or

    def initialize(*args, **options)
      case
      when args.length <= 1
        raise ShEx::OperandError, "Expected at least one operand, found #{args.length}"
      end
      super
    end
  end
end
