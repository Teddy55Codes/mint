module Mint
  class Parser
    def inline_function : Ast::InlineFunction?
      parse do |start_position|
        next unless char! '('
        whitespace

        arguments = list(
          terminator: ')',
          separator: ','
        ) { argument }
        whitespace

        next error :inline_function_expected_closing_parenthesis do
          expected "the closing parenthesis of an inline function", word
          snippet self
        end unless char! ')'
        whitespace

        type =
          if char! ':'
            whitespace
            next error :inline_function_expected_type do
              expected "the type of an inline function", word
              snippet self
            end unless item = self.type || type_variable
            whitespace
            item
          end

        body =
          block(
            -> { error :inline_function_expected_opening_bracket do
              expected "the opening bracket of an inline function", word
              snippet self
            end },
            -> { error :inline_function_expected_closing_bracket do
              expected "the closing bracket of an inline function", word
              snippet self
            end },
            -> { error :inline_function_expected_body do
              expected "the body of an inline function", word
              snippet self
            end })

        next unless body

        Ast::InlineFunction.new(
          arguments: arguments,
          from: start_position,
          to: position,
          file: file,
          body: body,
          type: type)
      end
    end
  end
end
