module Mint
  class Compiler
    def compile(node : Ast::RegexpLiteral) : Compiled
      compile node do
        [static_value(node).to_s] of Item
      end
    end
  end
end
