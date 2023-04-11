# frozen_string_literal: true

module Form
  module SubmitButton
    # Component for form submit button.
    class Component < ViewComponent::Base
      # @param [String] value
      # @param [Symbol] variant
      # @param [String] disable_with value for disabled version of submit button when form is submitted, optional
      # @param [String, TrueClass, FalseClass] confirm can be a String message for display or just true for a standard
      # message
      def initialize(value, variant: :primary, disable_with: nil, confirm: false, **options)
        @value = value
        @options = options
        @disable_with = disable_with
        @confirm = confirm
        @options[:class] = Array.wrap(@options[:class]).push('btn', "btn-#{variant}")
        @options[:data] = @options.fetch(:data, {})
        configure_form_disable
        configure_confirmation if confirm
      end

      def configure_confirmation
        message = @confirm.is_a?(String) ? @confirm : 'Are you sure?'
        confirm_action = 'click->form--submit-button--submit#confirm'
        @options[:data].merge!({ confirm: message,
                                 action: "#{confirm_action} #{@options[:data][:action]}" })
      end

      def configure_form_disable
        disable_with_value = @disable_with.is_a?(String) ? @disable_with : 'Processing...'
        @options[:data].merge!({ controller: 'form--submit-button--submit',
                                 action: 'click->form--submit-button--submit#disableSubmit',
                                 'disable-with': disable_with_value })
      end

      def call
        submit_tag @value, **@options
      end
    end
  end
end
