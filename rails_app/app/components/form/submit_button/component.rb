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
        @options[:class] = Array.wrap(@options[:class]).push('btn', "btn-#{variant}")
        @options[:data] = @options.fetch(:data, {})
        configure_confirmation if confirm
      end

      def configure_confirmation
        message = @confirm.is_a?(String) ? @confirm : 'Are you sure?'
        add_data_attributes(controller: 'form--submit-button--submit',
                            confirm: message,
                            action: 'click->form--submit-button--submit#confirm')
      end

      # add data attributes to options hash while maintaining order of multiple Stimulus actions
      def add_data_attributes(**attributes)
        @options[:data].merge!(attributes) do |k, old_value, new_value|
          k == :action ? "#{old_value} #{new_value}" : new_value
        end
      end

      def call
        submit_tag @value, **@options
      end
    end
  end
end
