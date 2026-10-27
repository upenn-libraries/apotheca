# frozen_string_literal: true

module CSVImport
  # Shared operation logic for CVSImport operations.
  class Operation < Dry::Operation
    # If a failure occurs, a message is added to the failure returned that can be displayed to the user. To generate
    # the message, the :error key is used to look up a custom message in operations.en.yml. If a message is not found,
    # a generic one is created from the error key. All Failure attributes besides :error and :exception are passed
    # to the locale so messages can be customized.
    # @param failure [Hash] data within failure monad
    def on_failure(failure)
      failure[:message] = I18n.t(failure[:error],
                                 scope: "operations.csv_import.#{self.class.to_s.demodulize.underscore}.failures",
                                 default: failure[:error].to_s.humanize,
                                 exception_message: failure[:exception]&.message,
                                 **failure.except(:exceptions, :error))
    end
  end
end
