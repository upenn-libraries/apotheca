# frozen_string_literal: true

module ImportService
  class Process
    # Import class to create an Item and its Assets.
    class Create < Base
      attr_reader :created_by

      # Initializes object to conduct import. For the time being this class will only import Items.
      #
      # @param (see Base#initialize)
      # @param [String] :created_by
      def initialize(**args)
        super

        # TODO: created_at, thumbnail
        @created_by = args[:created_by]
        # @publish    = args.fetch(:publish, 'false').casecmp('true').zero?
      end

      # Validates that Item can be created with the arguments given.
      def validate
        super

        @errors << 'human_readable_name must be provided to create an object' unless human_readable_name
        @errors << 'assets must be provided to create an object' unless asset_set
        @errors << 'metadata must be provided to create an object' if descriptive_metadata.blank?

        if unique_identifier
          @errors << "\"#{unique_identifier}\" already assigned to an item" if find_item(unique_identifier)
          @errors << "\"#{unique_identifier}\" is not minted" unless ark_exists?(unique_identifier)
        end

        @errors << 'asset storage and path must be provided' unless asset_set&.file_locations?

        # Validate that all filenames are listed.
        if asset_set&.valid? && asset_set&.file_locations?
          missing = asset_set.reject(&:file?).map(&:filename)
          @errors << "assets contains the following invalid filenames: #{missing.join(', ')}" if missing.present?
        end

        puts asset_set.file_locations.filenames

        # puts asset_set.all.first.file_location
      end

      # Runs process to create an Item.
      #
      # @return [Dry::Monads::Success|Dry::Monads::Failure]
      def run
        return failure(details: @errors) unless valid? # Validate before processing data.

        # Create all the assets
        assets_result = batch_create_assets(
          asset_set.all, { created_by: created_by, imported_by: imported_by }
        )

        return assets_result if assets_result.failure?

        all_assets = assets_result.value!
        all_asset_map = all_assets.index_by(&:original_filename) # filename to asset
        arranged_assets = asset_set.arranged.map { |a| all_asset_map[a.filename].id }

        # Create item and attach the assets
        item_attributes = {
          thumbnail_asset_id: all_asset_map[thumbnail]&.id,
          human_readable_name: human_readable_name,
          created_by: created_by || imported_by,
          updated_by: imported_by,
          internal_notes: internal_notes,
          descriptive_metadata: descriptive_metadata,
          structural_metadata: structural_metadata.merge({ arranged_asset_ids: arranged_assets }),
          asset_ids: all_assets.map(&:id)
        }

        CreateItem.new.call(item_attributes) do |result|
          result.success { |i| Success(i) }
          result.failure do |failure_hash|
            delete_assets(all_assets)
            failure(**failure_hash)
          end
        end
      rescue StandardError => e
        Honeybadger.notify(e) # Sending full error to Honeybadger.
        failure(exception: e)
      end

      private

      # Queries EZID to check if a given ark already exists.
      #
      # @return true if ark exists
      # @return false if ark does not exist
      def ark_exists?(ark)
        Ezid::Identifier.find(ark)
        true
      rescue StandardError # EZID gem raises unexpected errors when ark isn't found.
        false
      end
    end
  end
end
