# frozen_string_literal: true

module ImportService
  class Process
    # Import class to create an Item and its Assets.
    class Create < Base
      attr_reader :created_by

      # Initializes object to create item.
      #
      # @param (see Base#initialize)
      # @param [Hash] :assets # gets converted to an AssetSet
      # @param [String] :created_by
      def initialize(**args)
        super

        @created_by = args[:created_by]
        @asset_set  = args[:assets].blank? ? nil : AssetSet.new(**args[:assets])
      end

      # Validates that Item can be created with the arguments given.
      def validate
        super

        @errors << 'human_readable_name must be provided to create an object' unless human_readable_name
        @errors << 'assets must be provided to create an object' unless asset_set
        @errors << 'metadata must be provided to create an object' if descriptive_metadata.blank?

        if unique_identifier
          @errors << "\"#{unique_identifier}\" already assigned to an item" if item
          @errors << "\"#{unique_identifier}\" is not minted" unless ark_exists?(unique_identifier)
        end

        @errors << 'asset storage and path must be provided' unless asset_set&.file_locations?

        # Validate that all filenames are listed.
        if asset_set&.valid? && asset_set&.file_locations?
          missing = asset_set.reject(&:file?).map(&:filename)
          @errors << "assets contains the following invalid filenames: #{missing.join(', ')}" if missing.present?
        end

        # Validate that provided thumbnail exists
        if thumbnail.present? && asset_set.file_locations.filenames.exclude?(thumbnail)
          @errors << "provided thumbnail doesn't exist"
        end
      end

      # Runs process to create an Item.
      #
      # @return [Dry::Monads::Success|Dry::Monads::Failure]
      def run
        return failure(details: @errors) unless valid? # Validate before processing data.

        # Create all the assets
        assets_result = batch_create_assets(
          asset_set.all, { created_by: created_by,
                           imported_by: imported_by,
                           **ocr_options }
        )

        return assets_result if assets_result.failure?

        all_assets = assets_result.value!
        all_asset_map = all_assets.index_by(&:original_filename) # filename to asset
        arranged_assets = asset_set.arranged.map { |a| all_asset_map[a.filename].id }

        # Create item and attach the assets
        item_attributes = {
          unique_identifier: unique_identifier,
          thumbnail_asset_id: all_asset_map[thumbnail]&.id,
          human_readable_name: human_readable_name,
          created_by: created_by || imported_by,
          updated_by: imported_by,
          internal_notes: internal_notes,
          descriptive_metadata: descriptive_metadata,
          structural_metadata: structural_metadata.merge({ arranged_asset_ids: arranged_assets }),
          asset_ids: all_assets.map(&:id)
        }.merge(item_args)

        CreateItem.new.call(item_attributes) do |result|
          result.success do |i|
            publish ? publish_item(i) : Success(i)
          end

          result.failure do |failure_hash|
            delete_assets(all_assets)
            failure(**failure_hash)
          end
        end
      rescue StandardError => e
        failure(exception: e)
      end
    end
  end
end
