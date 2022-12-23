# frozen_string_literal: true

module Form
  module Field
    module Label
      # Component that renders label for input.
      class Component < ViewComponent::Base
        attr_reader :text

        def initialize(text, **options)
          @text = text.to_s.titlecase
          @options = options

          @options[:col] = { sm: 2 } unless @options.key?(:col)
        end

        def call
          render(ColumnComponent.new(:label, **@options)) { text }
        end
      end
    end
  end
end