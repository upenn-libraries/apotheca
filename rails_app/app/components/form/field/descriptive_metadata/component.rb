# frozen_string_literal: true

module Form
  module Field
    module DescriptiveMetadata
      # Input for descriptive metadata fields. Supports multivalued fields.
      class Component < ViewComponent::Base
        def initialize(config:, **options)
          @config = config
          @options = options

          @options[:subfields] = @config[:subfields]
        end

        def call
          case @config[:type]
          when :text
            @options[:field] << '[value]'
            @options[:value] = @options[:value].map { |v| v.nil? ? nil : v[:value] }

            # TODO: if a text field had a subfield a new class would have to be created to support this.
            render(FormControl::Component.new(type: :text, **@options))
          when :term
            render(Term::Component.new(**@options))
          end
        end
      end
    end
  end
end
