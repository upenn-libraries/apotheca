# frozen_string_literal: true

module ImportService
  class Process
    # Import class to update an Item and its Assets.
    class Update < Base
      # (see Base#initialize)
      def initialize(**args)
        super
      end

      # Validates that Item can be updated with the information given.
      def validate
        super

        if unique_identifier
          @errors << 'unique_identifier does not belong to an Item' unless find_item(unique_identifier)
        else
          @errors << 'unique_identifier must be provided when updating an Item'
        end
      end

      def run
        failure(details: ['Update process not yet implemented'])
      end
    end
  end
end
