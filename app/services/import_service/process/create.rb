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
        @errors << 'assets must be provided to create an object' unless assets
        @errors << 'metadata must be provided to create an object' if descriptive_metadata.blank?

        if unique_identifier
          @errors << "\"#{unique_identifier}\" already assigned to an item" if find_item(unique_identifier)
          @errors << "\"#{unique_identifier}\" is not minted" unless ark_exists?(unique_identifier)
        end

        # Validate that all filenames listed in structural metadata.
        if assets&.valid?
          missing = assets.missing_files
          @errors << "assets contains the following invalid filenames: #{missing.join(', ')}" if missing.present?
        end
      end

      # TODO: think about using structured/unstructured instead of arranged/unarranged

      # Runs process to create an Item.
      #
      # @return [Dry::Monads::Success|Dry::Monads::Failure]
      def run
        return failure(details: @errors) unless valid? # Validate before processing data.

        # Create all the assets
        assets_result = batch_create_assets(assets.all)

        return assets_result if assets_result.failure?

        all_assets = assets_result.value!
        all_asset_map = all_assets.index_by { |a| a[:original_filename] } # filename to asset
        arranged_assets = assets.arranged.map { |a| all_asset_map[a[:original_filename]].id }

        # Create item and attach the assets
        item_attributes = {
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
        # Honeybadger.notify(e) # Sending full error to Honeybadger.
        failure(exception: e)
      end

      private

      def batch_create_assets(assets_data)
        asset_list = []
        error = nil

        # Create all assets, break out of loop if there is an error making an asset.
        assets_data.each do |asset|
          result = create_asset(asset)

          if result.failure?
            result.failure[:details].prepend("Error raised when generating #{asset[:original_filename]}")
            error = result
            break
          else
            asset_list << result.value!
          end
        end

        if error.present?
          delete_assets(asset_list)
          error
        else
          Success(asset_list)
        end
      end

      def delete_assets(asset_list)
        asset_list.each { |a| DeleteAsset.new.call(id: a.id) }
      end

      def create_asset(asset)
        create_transaction = CreateAsset.new
        update_transaction = UpdateAsset.new.with_step_args(generate_derivatives: [async: false])

        create_transaction.call(created_by: created_by || imported_by, updated_by: imported_by, **asset) do |result|
          result.success do |a|
            update_args = {
              id: a.id,
              file: assets.file_for(asset[:original_filename]),
              updated_by: imported_by,
              original_filename: asset[:original_filename]
            }

            update_transaction.call(**update_args) do |update_result|
              update_result.success { |u| Success(u) } # TODO: might want to unlink temp file here manually or do it in the transaction
              update_result.failure do |failure_hash|
                DeleteAsset.new.call(id: a.id)
                failure(**failure_hash)
              end
            end
          end

          result.failure do |failure_hash|
            failure(**failure_hash)
          end
        end
      end

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
