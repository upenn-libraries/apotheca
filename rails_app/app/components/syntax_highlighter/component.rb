# frozen_string_literal: true

module SyntaxHighlighter
  # Component that adds syntax highlighting to the text given using Rouge.
  class Component < ViewComponent::Base
    attr_reader :text, :language

    def initialize(text:, language:)
      @text = text
      @language = language
    end

    def call
      render(BaseComponent.new(:pre, class: 'highlight')) do
        sanitize(highlighted_text, attributes: %w[style])
      end
    end

    private

    def highlighted_text
      formatter = Rouge::Formatters::HTMLInline.new(Rouge::Themes::Base16::Solarized)
      lexer = Rouge::Lexer.find(language)
      formatter.format(lexer.lex(text))
    end
  end
end
