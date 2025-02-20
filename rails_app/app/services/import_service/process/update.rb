# frozen_string_literal: true

module ImportService
  class Process
    # Import class to update an Item and its Assets.
    class Update < Base
      attr_reader :created_assets

      # Initializes object to update item.
      #
      # @param (see Base#initialize)
      # @param [Hash] :asset # gets converted to an AssetSet
      def initialize(**args)
        super

        @asset_set = args[:assets].blank? ? nil : AssetSet.new(**args[:assets])
        @created_assets = []
      end

      # Validates that Item can be updated with the information given.
      def validate
        super

        @errors << 'unique_identifier must be provided when updating an Item' unless unique_identifier
        @errors << 'unique_identifier does not belong to an Item' if unique_identifier && item.nil?

        # ensure that a user-specified thumbnail exists in the asset set (incoming assets) or the existing assets
        if thumbnail.present? && asset_set.present? && asset_set.file_locations.filenames.exclude?(thumbnail)
          @errors << 'provided thumbnail does not exist in provided assets'
        elsif thumbnail.present? && @errors.empty? && existing_assets.map(&:original_filename).exclude?(thumbnail)
          @errors << 'provided thumbnail does not exist in existing assets'
        end
      end

      # Runs process to update Item and update or create Assets as appropriate.
      def run
        return failure(details: @errors) unless valid? # Validate before processing data.

        filename_to_asset = existing_assets.index_by(&:original_filename)

        if asset_set
          existing_filenames = existing_assets.map(&:original_filename)
          import_filenames = asset_set.map(&:filename)

          # All current assets must be represented in import data. Return error if assets are missing from asset_set.
          missing_filenames = existing_filenames - import_filenames

          if missing_filenames.present?
            return failure(
              error: 'All assets must be represented when updating assets; the following assets are missing:',
              details: missing_filenames
            )
          end

          # New assets
          new_filenames = import_filenames - existing_filenames

          if new_filenames.present?
            create_assets_result = create_new_assets(new_filenames)

            return create_assets_result if create_assets_result.failure?
          end

          # Map of filename to assets (includes existing and newly created assets)
          filename_to_asset = filename_to_asset.merge(created_assets.index_by(&:original_filename))

          arranged_asset_ids = asset_set.arranged.map { |a| filename_to_asset[a.filename].id }
        end

        # Update Item
        item_attributes = {
          thumbnail_asset_id: filename_to_asset[thumbnail]&.id,
          id: item.id,
          optimistic_lock_token: item.optimistic_lock_token,
          human_readable_name: human_readable_name,
          updated_by: imported_by,
          internal_notes: internal_notes,
          descriptive_metadata: descriptive_metadata,
          structural_metadata: structural_metadata
        }.compact_blank.merge(item_args)

        if asset_set
          item_attributes[:structural_metadata] = item_attributes.fetch(:structural_metadata, {})
                                                                 .merge(arranged_asset_ids: arranged_asset_ids)
          item_attributes[:asset_ids] = Array.wrap(item.asset_ids) + created_assets.map(&:id)
        end

        # Save response before updating item.
        regenerate = regenerate_asset_derivatives?

        UpdateItem.new.call(item_attributes) do |result|
          result.success do |i|
            if asset_set.present?
              update_result = update_existing_assets
              return update_result unless update_result.success?
            end

            if regenerate
              regenerate_result = GenerateAllDerivatives.new.call(id: i.id.to_s, updated_by: imported_by)
              return regenerate_result unless regenerate_result.success?
            end

            publish ? publish_item(i) : Success(i)
          end

          result.failure do |failure_hash|
            delete_assets(created_assets)
            failure(**failure_hash)
          end
        end
      rescue StandardError => e
        failure(exception: e)
      end

      private

      # Determines whether asset derivatives should be generated. Asset derivatives
      # should be regenerated if the ocr_type, viewing_direction or language has changed.
      def regenerate_asset_derivatives?
        return false if item.ocr_type.nil? && item_args[:ocr_type].nil?
        return true if descriptive_metadata.key?(:language) && item.language_codes.uniq.sort != ocr_language.uniq.sort
        return true if item_args.key?(:ocr_type) && item_args[:ocr_type] != item.ocr_type
        return true if structural_metadata.key?(:viewing_direction) &&
                       structural_metadata[:viewing_direction] != item.structural_metadata.viewing_direction

        false
      end

      def existing_assets
        @existing_assets ||= query_service.find_many_by_ids(ids: item.asset_ids || [])
      end

      # Creates new assets and sets the `created_assets` instance variable.
      def create_new_assets(filenames)
        # If new assets are loaded require that file location is provided.
        unless asset_set&.file_locations?
          return failure(details: ['asset storage and path must be provided to create new assets'])
        end

        new_assets_data = filenames.map { |f| asset_set.find { |a| a.filename == f } }

        # Checking that all new assets have a file present in storage
        missing = new_assets_data.reject(&:file?).map(&:filename)
        return failure(details: ["Files in storage missing for: #{missing.join(', ')}"]) if missing.present?

        # Creating new assets
        result = batch_create_assets(new_assets_data, { imported_by: imported_by, **ocr_options })
        @created_assets = result.value! if result.success?
        result
      end

      # Updating all existing assets if new data has been provided.
      #
      # @return [Dry::Monads::Success] if all existing assets were updated successfully
      # @return [Dry::Monads::Failure] if any of the assets failed, failures are aggregated
      def update_existing_assets
        results = existing_assets.map do |asset|
          asset_data = asset_set.find { |a| a.filename == asset.original_filename }

          asset_data.update_asset(asset: asset, imported_by: imported_by, **ocr_options).then do |result|
            if result.success?
              result
            else
              e = result.failure
              error = e.delete(:error)
              error = error.to_s.humanize if error.is_a? Symbol
              failure(error: "Error occurred updating #{asset.original_filename}: #{error}", **e)
            end
          end
        end

        if results.all?(&:success?)
          Success(results.map(&:value!))
        else
          failure(
            error: 'All changes were applied except the updates to the asset(s) below. These issues must be fixed manually:',
            details: results.select(&:failure?).map { |f| f.failure[:details] }.flatten
          )
        end
      end
    end
  end
end
