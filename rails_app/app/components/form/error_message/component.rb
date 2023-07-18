# frozen_string_literal: true

module Form
  module ErrorMessage
    # Component for displaying error messages.
    class Component < ViewComponent::Base
      attr_reader :error, :validation_errors, :exception

      # This component renders error messages. It requires an `error` hash that can include the following keys:
      #   - :error
      #   - :change_set
      #   - :exception
      #
      # If `change_set` responds to `errors` it will iterate through the validation messages and display the output.
      # ActiveRecord objects will return ActiveRecord::Errors and change sets will return
      # Reform::Form::ActiveModel::Validations::Result::ResultErrors. Both of these error classes respond to
      # `full_messages`.
      #
      # @param [Hash] error_args the arguments to create a error message with.
      # @option error_args [String] :error message
      # @option error_args [Valkyrie::ChangeSet] :change_set with validation errors
      # @option error_args [Exception] :exception object
      def initialize(error_args, **options)
        error_args ||= {}

        @error = error_args[:error]
        @exception = error_args[:exception]
        @change_set = error_args[:change_set]
        @options = options

        @validation_errors = @change_set.errors if @change_set.respond_to?(:errors)
      end

      def render?
        @error.present?
      end
    end
  end
end
