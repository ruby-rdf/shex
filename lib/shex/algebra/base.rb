module ShEx::Algebra
  ##
  class Base < Operator::Binary
    NAME = :base

    def execute(queryable, options = {}, &block)
      debug(options) {"Base"}
      @solutions = queryable.query(operands.last, options.merge(depth: options[:depth].to_i + 1), &block)
    end
  end
end
