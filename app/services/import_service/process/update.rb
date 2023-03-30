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
        return failure(details: @errors) unless valid? # Validate before processing data.

        item = find_item(unique_identifier)

        # Update Item
        item_attributes = {
          id: item.id,
          human_readable_name: human_readable_name,
          updated_by: imported_by,
          internal_notes: internal_notes,
          descriptive_metadata: descriptive_metadata,
          structural_metadata: structural_metadata,
        }.compact_blank

        UpdateItem.new.call(item_attributes) do |result|
          result.success { |i| Success(i) }
          result.failure do |failure_hash|
            failure(**failure_hash)
          end
        end
      rescue StandardError => e
        # Honeybadger.notify(e) # Sending full error to Honeybadger.
        failure(exception: e)
      end
    end
  end
end
