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
        @message = @confirm.is_a?(String) ? @confirm : 'Are you sure?'
        @id = "submit_button_component_#{object_id}"
        @options[:class] = Array.wrap(@options[:class]).push('btn', "btn-#{variant}")
        @options[:data] = @options.fetch(:data, {})
        @variant = normalize_variant(variant)
        configure_confirmation if confirm
      end

      def normalize_variant(variant)
        variant.to_s.gsub('outline-', '').gsub(/secondary|link/, 'primary')
      end

      def configure_confirmation
        add_data_attributes('bs-toggle': 'modal',
                            'bs-target': "##{@id}")
      end

      # add data attributes to options hash while maintaining order of multiple Stimulus actions
      def add_data_attributes(**attributes)
        @options[:data].merge!(attributes) do |k, old_value, new_value|
          k == :action ? "#{old_value} #{new_value}" : new_value
        end
      end
    end
  end
end
