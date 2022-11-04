# frozen_string_literal: true

module Form
  module ErrorMessage
    # Component for displaying error messages.
    class Component < ViewComponent::Base
      attr_reader :overview, :validation_errors, :exception

      # This component renders error messages. It accepts a error parameters from Transactions and from ActiveRecord
      # models. It requires an `error` parameter that can be provided in different formats. The following are all
      # valid `error` values:
      #   - [:validation_error, object_responding_to_errors]
      #   - [:failure, exception_object]
      #   - :failed_to_load
      #   - 'Failed to Load'
      #
      # If an array is provided and the second value responds to `errors` it will iterate through the messages
      # and display the output. ActiveRecord objects will return ActiveRecord::Errors and change sets will return
      # Reform::Form::ActiveModel::Validations::Result::ResultErrors. Both of these error classes respond to
      # `full_messages`. If the second value does not respond to `errors` it will be ignored.
      #
      # @param [String|Array] error information, which can take multiple forms
      # @param [Boolean] show flag
      def initialize(error, show: true)
        error = Array.wrap(error)

        @overview = error[0]
        @show = show

        if error[1].respond_to?(:errors)
          @validation_errors = error[1].errors
        elsif error[1].is_a? Exception
          @exception = error[1]
        end
      end

      def render?
        @overview.present? && @show
      end
    end
  end
end

