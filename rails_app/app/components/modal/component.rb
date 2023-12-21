# frozen_string_literal: true

module Modal
  class Component < ViewComponent::Base
    def initialize(value:, body:, button_variant: :primary, **options)
      @id = "modal_component_#{object_id}"
      @value = value
      @body = body
      @button_class = Array.wrap(@button_class).push('btn', "btn-#{button_variant}")
      @modal_class = configure_modal(options).join(' ')
      @preview = options[:preview]
    end

    def highlight(text, language)
      formatter = Rouge::Formatters::HTML.new
      lexer = Rouge::Lexer.find(language)
      formatter.format(lexer.lex(text))
    end

    private

    def configure_modal(attributes)
      classes = []
      classes << 'modal-dialog-scrollable' if attributes[:scrollable]
      classes << "modal-#{attributes[:modal_size]}" if attributes[:modal_size]
      classes
    end
  end
end
