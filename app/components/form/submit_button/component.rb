# frozen_string_literal: true

module Form
  module SubmitButton
    # Component for form submit button.
    class Component < ViewComponent::Base
      # @param [String] value
      # @param [Symbol] variant
      # @param [String, TrueClass, FalseClass] confirm can be a String message for display or just true for a standard
      # message
      def initialize(value, variant: :primary, confirm: false, **options)
        @value = value
        @options = options
        @confirm = confirm
        @options[:class] = @options.fetch(:class, []).push('btn', "btn-#{variant}")
        @options[:data] = @options.fetch(:data, {})
        configure_confirmation if confirm
      end

      def configure_confirmation
        message = @confirm.is_a?(String) ? @confirm : 'Are you sure?'
        @options[:data].merge!({ confirm: message,
                                 controller: 'form--submit-button--submit',
                                 action: 'click->form--submit-button--submit#confirm' })
      end

      def call
        submit_tag @value, **@options
      end
    end
  end
end
