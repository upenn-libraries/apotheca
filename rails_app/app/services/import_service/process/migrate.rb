# frozen_string_literal: true

module ImportService
  class Process
    # Import class to migrate an Item from Bulwark (Colenda) to Apotheca.
    class Migrate < Base
      attr_reader :created_by, :created_at, :first_published_at, :last_published_at

      # Initializes object to conduct migration.
      #
      # @param [String] :imported_by
      # @param [String] :unique_identifier
      def initialize(**args)
        @imported_by       = args[:imported_by]
        @unique_identifier = args[:unique_identifier]
        @publish           = args.fetch(:publish, 'false').casecmp('true').zero? # Not allowing for unpublishing
        @errors            = []
      end

      def validate
        @errors = [] # Clear out previously generated errors.

        # Validate fields provided in the CSV
        @errors << 'imported_by must always be provided' unless imported_by

        if unique_identifier
          @errors << "\"#{unique_identifier}\" has already been migrated" if find_item(unique_identifier)
          @errors << "\"#{unique_identifier}\" is not minted" unless ark_exists?(unique_identifier)
        else
          @errors << 'unique_identifier must be provided to migrate an Item'
        end

        return false if @errors.present?

        # Extract data from migration source and validate it
        extract_data_from_colenda

        @errors << 'human_readable_name must be provided to migrate an object' unless human_readable_name
        @errors << 'created_at must be provided to migrate an object' unless created_at
        @errors << 'created_by must be provided to migrate an object' unless created_by
        @errors << 'first_published_at must be provided to migrate an object' unless first_published_at
        @errors << 'last_published_at must be provided to migrate an object' unless last_published_at
        @errors << 'assets must be provided to migrate an object' unless asset_set
        @errors << 'metadata must be provided to migrate an object' if descriptive_metadata.blank?

        @errors.concat(descriptive_metadata.errors) if descriptive_metadata&.invalid?
        @errors.concat(asset_set.errors) if asset_set&.invalid?
      end

      # Runs process to migrate an Item.
      #
      # @return [Dry::Monads::Success|Dry::Monads::Failure]
      def run
        return failure(details: @errors) unless valid?

        # Create all the assets
        assets_result = batch_create_assets(
          asset_set.all,
          { migrated_from: 'Colenda', first_created_at: created_at, created_by: created_by, imported_by: imported_by }
        )

        return assets_result if assets_result.failure?

        # TODO: validate checksum of assets once they are transferred?

        all_assets = assets_result.value!
        all_asset_map = all_assets.index_by(&:original_filename) # filename to asset
        arranged_assets = asset_set.arranged.map { |a| all_asset_map[a.filename].id }

        # Create item and attach the assets
        item_attributes = {
          unique_identifier: unique_identifier,
          human_readable_name: human_readable_name,
          created_by: created_by,
          first_created_at: created_at,
          updated_by: imported_by,
          first_published_at: first_published_at,
          last_published_at: last_published_at,
          internal_notes: ["Item Imported from Colenda on #{DateTime.current}"],
          descriptive_metadata: descriptive_metadata.to_apotheca_metadata,
          structural_metadata: structural_metadata.merge({ arranged_asset_ids: arranged_assets }),
          asset_ids: all_assets.map(&:id)
        }

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

      private

      # Pull information from Colenda
      def extract_data_from_colenda
        connection = Faraday.new(Settings.migration.colenda_url) do |conn|
          conn.request :retry, exceptions: Faraday::Retry::Middleware::DEFAULT_EXCEPTIONS + [Faraday::ConnectionFailed],
                               interval: 1, max: 3
        end

        response = connection.get("migration/#{CGI.escape(unique_identifier)}/serialized")

        return failure(error: 'Error extracting data from Colenda:', details: [response.body]) unless response.success?

        data = JSON.parse(response.body).deep_symbolize_keys

        @human_readable_name  = data[:human_readable_name]
        @descriptive_metadata = ColendaMetadata.new(data[:descriptive_metadata]) if data[:descriptive_metadata].present?
        @structural_metadata  = data.fetch(:structural_metadata, {})
        @created_by = data[:created_by]
        @created_at = DateTime.parse(data[:created_at]) if data[:created_at]
        @first_published_at = DateTime.parse(data[:first_published_at]) if data[:first_published_at]
        @last_published_at = DateTime.parse(data[:last_published_at]) if data[:last_published_at]
        @asset_set = MigrationAssetSet.new(storage: Settings.migration.storage, **data[:assets]) if data[:assets].present?
      end
    end
  end
end
