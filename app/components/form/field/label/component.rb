# frozen_string_literal: true

module Form
  module Field
    module Label
      # Component that renders label for input.
      class Component < ViewComponent::Base
        attr_reader :text

        def initialize(text, size: nil, **options)
          @text = text.to_s.titlecase
          @options = options

          if @options[:col]
            @options[:class] = Array.wrap(@options[:class]).append('col-form-label')
            @options[:class] = @options[:class].append("col-form-label-#{size}") if size
          end
        end

        def call
          if @options[:col]
            render(ColumnComponent.new(:label, **@options)) { text }
          else
            render(BaseComponent.new(:label, **@options)) { text }
          end
        end
      end
    end
  end
end