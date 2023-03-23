# frozen_string_literal: true

module ImportService
  class Process
    # Import class to update an Item and its Assets.
    class Update < Base
      # Validates that Item can be updated with the information given.
      def validate
        super

        @errors << 'unique_identifier must be provided when updating an Item' unless unique_identifier
        @errors << 'unique_identifier does not belong to an Item' if unique_identifier && !find_item(unique_identifier)
      end

      def run
        failure(details: ['Update process not yet implemented'])
      end
    end
  end
end
