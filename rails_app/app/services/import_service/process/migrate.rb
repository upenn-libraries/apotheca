# frozen_string_literal: true

module ImportService
  class Process
    # Import class to migrate an Item from Bulwark (Colenda) to Apotheca.
    class Migrate < Base
      attr_reader :created_by, :created_at, :first_published_at, :last_published_at

      # Initializes object to conduct migration.
      #
      # @param (see Base#initialize)
      # @param [String] :imported_by
      # @param [String] :unique_identifier
      def initialize(**args)
        @imported_by       = args[:imported_by]
        @unique_identifier = args[:unique_identifier]
        @errors            = []
      end

      # Validate before fetching data from Colenda.
      def validate
        @errors = [] # Clear out previously generated errors.

        @errors << 'imported_by must always be provided' unless imported_by

        if unique_identifier
          @errors << "\"#{unique_identifier}\" has already been migrated" if find_item(unique_identifier)
          # @errors << "\"#{unique_identifier}\" is not minted" unless ark_exists?(unique_identifier)
        else
          @errors << 'unique_identifier must be provided to create an object'
        end
      end

      # Runs process to migrate an Item.
      #
      # @return [Dry::Monads::Success|Dry::Monads::Failure]
      def run
        return failure(details: @errors) unless valid?

        # Pull information from colenda
        uri = URI.parse(Settings.migration.colenda_url)
                 .merge("migration/#{CGI.escape(unique_identifier)}/serialized")

        response = Faraday.get(uri.to_s)

        return failure(error: 'Error extracting data from Colenda', details: [response.body]) unless response.success?

        data = JSON.parse(response.body).deep_symbolize_keys

        # TODO: Add internal note saying: 'Item imported from Colenda/Bulwark on XXXX'
        @human_readable_name  = data[:human_readable_name]
        @descriptive_metadata = convert_to_new_metadata_schema(data.fetch(:descriptive_metadata, {}))
        @structural_metadata  = data.fetch(:structural_metadata, {})
        @created_by = data[:created_by]
        @created_at = DateTime.parse(data[:created_at]) if data[:created_at]
        @first_published_at = DateTime.parse(data[:first_published_at]) if data[:first_published_at]
        @last_published_at = DateTime.parse(data[:last_published_at]) if data[:last_published_at]
        @asset_set = data[:assets].blank? ? nil : MigrationAssetSet.new(storage: Settings.migration.storage, **data[:assets])

        validate_colenda_data

        return failure(details: @errors) if @errors.present?

        # Create all the assets
        assets_result = batch_create_assets(
          asset_set.all, { migrated_from: 'Colenda', date_created: created_at, created_by: created_by, imported_by: imported_by }
        )

        return assets_result if assets_result.failure?

        # TODO: validate checksum of assets once they are transferred?

        all_assets = assets_result.value!
        all_asset_map = all_assets.index_by(&:original_filename) # filename to asset
        puts all_asset_map.keys.to_s
        arranged_assets = asset_set.arranged.map { |a| all_asset_map[a.filename].id }

        # Create item and attach the assets
        item_attributes = {
          unique_identifier: unique_identifier,
          human_readable_name: human_readable_name,
          created_by: created_by,
          date_created: created_at,
          updated_by: imported_by,
          first_published_at: first_published_at,
          last_published_at: last_published_at,
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
        Rails.logger.debug e.backtrace.join("\n")
        failure(exception: e)
      end

      private

      def validate_colenda_data
        @errors = [] # Clear out previously generated errors.

        @errors << 'human_readable_name must be provided to create an object' unless human_readable_name
        @errors << 'created_at must be provided to create an object' unless created_at
        @errors << 'created_by must be provided to create an object' unless created_by
        @errors << 'assets must be provided to create an object' unless asset_set
        @errors << 'metadata must be provided to create an object' if descriptive_metadata.blank?
        @errors.concat(asset_set.errors) if asset_set&.invalid?
      end

      def convert_to_new_metadata_schema(metadata)
        metadata.delete(:includes)

        metadata[:physical_location] = metadata.delete(:call_number)
        metadata[:extent] = metadata.delete(:format)
        metadata[:note] = metadata.delete(:note)
        metadata[:physical_format] = metadata.delete(:item_type)

        metadata[:description] ||= []
        metadata[:description] += metadata.delete(:abstract) || []

        # All names get merged into `name`
        metadata[:name] = []
        metadata[:name] += metadata.delete(:personal_name) || []
        metadata[:name] += metadata.delete(:corporate_names) || []
        metadata[:name] += (metadata.delete(:contributor) || []).map do |n|
          {
            value: n,
            role: [{ value: 'Contributor', uri: 'https://id.loc.gov/vocabulary/relators/ctb' }]
          }
        end
        metadata[:name] += (metadata.delete(:creator) || []).map do |n|
          {
            value: n,
            role: [{ value: 'Creator', uri: 'https://id.loc.gov/vocabulary/relators/cre' }]
          }
        end

        # First title goes to `title`, rest of titles go to `alt_title`.
        if (titles = metadata.delete(:title))
          metadata[:title] = [titles[0]]
          metadata[:alt_title] = titles[1..]
        end

        # Moving rights URIs into `rights` and moving any textual rights to `rights_note`.
        # TODO: URIs need to be moved to URI fields, need to have a map of URI to value
        rights_uris = metadata.fetch(:rights, [])
                              .select { |r| r.match(/\Ahttps?:\/\/(rightsstatements|creativecommons)\.org\S+\Z/) }
        metadata[:rights_note] = metadata.fetch(:rights, []) - rights_uris
        metadata[:rights] = rights_uris # TODO: probably need a map from uri to value...

        # Add uri to languages
        metadata[:language] = metadata.fetch(:language, []).map do |l|
          if (language = ISO_639.find_by_english_name(l))
            { value: language.english_name, uri: "https://id.loc.gov/vocabulary/iso639-2/#{language.alpha3}" }
          else
            { value: l }
          end
        end

        metadata.compact_blank!
        metadata.transform_values { |values| values.map { |v| v.is_a?(Hash) ? v : { value: v } } }
      end
    end
  end
end
