module ShEx::Algebra
  ##
  class Prefix < Operator::Binary
    NAME = :prefix

    def execute(queryable, options = {}, &block)
      debug(options) {"Prefix"}
      @solutions = queryable.query(operands.last, options.merge(depth: options[:depth].to_i + 1), &block)
    end
  end
end
