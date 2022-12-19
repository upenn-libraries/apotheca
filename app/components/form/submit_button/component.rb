# frozen_string_literal: true

module Form
  module SubmitButton
    # Component for form submit button.
    class Component < ViewComponent::Base
      def initialize(value, variant: :primary, **options)
        @value = value
        @options = options

        @options[:class] = Array.wrap(@options[:class]).push('btn', "btn-#{variant}")
      end

      def call
        submit_tag @value, **@options
      end
    end
  end
end
