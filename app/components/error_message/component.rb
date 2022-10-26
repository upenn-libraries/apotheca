# frozen_string_literal: true

# Component for displaying error messages.
module ErrorMessage
  class Component < ViewComponent::Base

    attr_reader :overview, :validation_errors, :exception

    # This component renders error messages. It accepts a error parameters from Transactions and from ActiveRecord
    # models. It requires an `error` parameter that can be provided in different formats. The following are all
    # valid `error` values:
    #   - [:validation_error, object_responding_to_full_messages]
    #   - [:failure, exception_object]
    #   - :failed_to_load
    #   - 'Failed to Load'
    #
    # If an array is provided and the second value responds to `full_messages` it will iterate through the messages
    # and display the output. ActiveRecord::Errors and Reform::Form::ActiveModel::Validations::Result::ResultErrors both
    # respond to `full_messages`. If the second value does not respond to `full_messages` it will be ignored.
    #
    # @param [String|Array] error information, which can take multiple forms
    def initialize(error)
      error = Array.wrap(error)

      @overview = error[0]

      if error[1].respond_to?(:full_messages)
        @validation_errors = error[1]
      elsif error[1].is_a? Exception
        @exception = error[1]
      end
    end

  end
end
