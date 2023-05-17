# frozen_string_literal: true

module ImportService
  class Process
    # Import class to update an Item and its Assets.
    class Update < Base
      attr_reader :created_assets

      def initialize(**args)
        super

        @created_assets = []
      end

      # Validates that Item can be updated with the information given.
      def validate
        super

        @errors << 'unique_identifier must be provided when updating an Item' unless unique_identifier
        @errors << 'unique_identifier does not belong to an Item' if unique_identifier && !find_item(unique_identifier)
      end

      # Runs process to update Item and update or create Assets as appropriate.
      def run
        return failure(details: @errors) unless valid? # Validate before processing data.

        if asset_set
          existing_filenames = existing_assets.map(&:original_filename)
          import_filenames = asset_set.map(&:filename)

          # Assets not represented in data given. All current assets must be represented in import data.
          missing_filenames = existing_filenames - import_filenames
          return failure(details: ["Missing the following assets: #{missing_filenames.join(', ')}. All assets must be represented when updating assets"]) if missing_filenames.present?

          # New assets
          new_filenames = import_filenames - existing_filenames

          if new_filenames.present?
            create_assets_result = create_new_assets(new_filenames)

            return create_assets_result if create_assets_result.failure?
          end

          # Map of filename to assets (includes existing and newly created assets)
          filename_to_asset = existing_assets.index_by { |a| a[:original_filename] }
                                             .merge(created_assets.index_by { |a| a[:original_filename] })

          arranged_asset_ids = asset_set.arranged.map { |a| filename_to_asset[a.filename].id }
        end

        # Update Item
        item_attributes = {
          id: item.id,
          optimistic_lock_token: item.optimistic_lock_token,
          human_readable_name: human_readable_name,
          updated_by: imported_by,
          internal_notes: internal_notes,
          descriptive_metadata: descriptive_metadata,
          structural_metadata: structural_metadata
        }.compact_blank

        if asset_set
          item_attributes[:structural_metadata] = item_attributes.fetch(:structural_metadata, {}).merge(arranged_asset_ids: arranged_asset_ids)
          item_attributes[:asset_ids] = item.asset_ids + created_assets.map(&:id)
        end

        UpdateItem.new.call(item_attributes) do |result|
          result.success do |i|
            return Success(i) unless asset_set.blank?

            update_result = update_existing_assets
            update_result.success? ? Success(i) : update_result
          end
          result.failure do |failure_hash|
            delete_assets(created_assets)
            failure(**failure_hash)
          end
        end
      rescue StandardError => e
        # Honeybadger.notify(e) # Sending full error to Honeybadger.
        failure(exception: e)
      end

      private

      def item
        @item ||= find_item(unique_identifier)
      end

      def existing_assets
        @existing_assets ||= query_service.find_many_by_ids(ids: item.asset_ids || [])
      end

      # Creates new assets and sets the `created_assets` instance variable.
      def create_new_assets(filenames)
        # If new assets are loaded require that file location is provided
        return failure(details: ['asset storage and path must be provided to create new assets']) unless asset_set&.file_locations?

        # Checking that all new assets have a file present in storage
        missing = asset_set.missing_files(filenames)
        return failure(details: ["Files in storage missing for: #{missing.join(', ')}"]) if missing.present?

        # Creating new assets
        new_assets_data = filenames.map { |f| asset_set.find { |a| a.filename == f } }
        result = batch_create_assets(new_assets_data, { created_by: imported_by })
        @created_assets = result.value! if result.success?
        result
      end

      # Updating all existing assets if new data has been provided.
      #
      # @return [Dry::Monads::Success] if all existing assets were updated successfully
      # @return [Dry::Monads::Failure] if any of the assets failed, failures are aggregated
      def update_existing_assets
        # TODO: think about structuring errors in something other than an array.
        results = existing_assets.map do |asset|
          asset_data = asset_set.find { |a| a.filename == asset.original_filename }
          r = update_asset(asset: asset, asset_data: asset_data)
          if r.failure?
            e = r.failure
            message = "Error occurred updating #{asset[:original_filename]} - #{e[:error]}"
            failure(details: [message], exception: e[:exception], change_set: e[:change_set])
          else
            r
          end
        end

        if results.all?(&:success?)
          Success(results.map(&:value!))
        else
          failure(
            error: :import_failed,
            details: results.select(&:failure?)
                            .map { |f| f.failure[:details] }
                            .flatten
                            .prepend('An error was raised while updating one or more assets. All changes were applied except the updates to the asset(s) below. These issues should be fixed manually.')
          )
        end
      end

      # Update an existing asset with new metadata or file. Asset is only updated if the file in storage has
      # changed or if the metadata that is given is different than the metadata already assigned.
      #
      # @param [AssetResource] asset to be updated
      # @param [ImportService::AssetData] asset_data to be used to update asset
      def update_asset(asset:, asset_data:)
        attributes = {}

        # Check if the asset preservation file needs to be updated
        if asset_data.file? && asset.technical_metadata.sha256 != asset_data.checksum_sha256
          attributes[:file] = asset_data.file
        end

        # Check if the metadata needs to be updated
        metadata = asset_data.resource_attributes
        attributes[:label] = metadata[:label] if metadata.key?(:label) && (asset.label != metadata[:label])
        attributes[:annotations] = metadata[:annotations] if metadata.key?(:annotations) && asset.annotations.map(&:text).difference(metadata[:annotations].pluck(:text))
        attributes[:transcriptions] = metadata[:transcriptions] if metadata.key?(:transcriptions) && asset.transcriptions.map(&:content).difference(metadata[:transcriptions].pluck(:contents))

        return Success(asset) if attributes.empty? # Don't process an update if not necessary.

        update_asset_transaction.call(
          id: asset.id,
          updated_by: imported_by,
          optimistic_lock_token: asset.optimistic_lock_token,
          **attributes
        )
      end
    end
  end
end
