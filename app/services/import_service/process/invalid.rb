# frozen_string_literal: true

module ImportService
  class Process
    # Import class to use when action is invalid.
    class Invalid < Base
      attr_reader :action

      def initialize(**args)
        super

        @action = args[:action]
      end

      def validate
        super

        @errors << "\"#{action}\" is not a valid import action" unless ACTIONS.include?(action)
      end

      def run
        failure(details: @errors) unless valid? # Validate before processing data.
      end
    end
  end
end
