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
      # @param [Hash] args the arguments to create a error message with.
      # @option args [String] :error message
      # @option args [Valkyrie::ChangeSet] :change_set with validation errors
      # @option args [Exception] :exception object
      def initialize(args)
        @error = args[:error]
        @exception = args[:exception]
        @change_set = args[:change_set]

        @validation_errors = @change_set.errors if @change_set&.respond_to?(:errors)
      end

      def render?
        @error.present?
      end
    end
  end
end

