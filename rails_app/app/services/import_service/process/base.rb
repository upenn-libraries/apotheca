# frozen_string_literal: true

module ImportService
  class Process
    # Base class for processing imports that includes logic that is required for
    # all imports. Import classes should inherit from this class.
    class Base
      include Dry::Monads[:result]

      attr_reader :errors, :imported_by, :descriptive_metadata, :structural_metadata, :publish,
                  :asset_set, :unique_identifier, :human_readable_name, :internal_notes, :thumbnail, :item_args

      # Initializes object to conduct import. For the time being this class will only import Items.
      #
      # @param [String] :imported_by
      # @param [String] :unique_identifier
      # @param [String] :human_readable_name
      # @param [Array<String>] :internal_notes
      # @param [Hash] :metadata  # gets mapped to descriptive_metadata
      # @param [Hash] :structural  # gets mapped to structural_metadata
      def initialize(**args)
        @thumbnail            = args[:thumbnail]
        @imported_by          = args[:imported_by]
        @unique_identifier    = args[:unique_identifier]
        @human_readable_name  = args[:human_readable_name]
        @internal_notes       = args[:internal_notes]
        @descriptive_metadata = args.fetch(:metadata, {})
        @structural_metadata  = args.fetch(:structural, {})
        @publish              = args.fetch(:publish, 'false').casecmp('true').zero? # Not allowing for unpublishing

        # Extracting top-level item attributes in a Hash, because we need to know if a key was present or not.
        # @todo Perhaps other values can be added to this hash, a refactor is probably in order.
        @item_args            = args.slice(:ocr_strategy)
        @errors               = []
      end

      # Validates that import has all the necessary information. These checks are meant
      # to be lightweight checks that can be done before starting the import process.
      # Errors are stored in an instance variable. Subclasses should override this method
      # and call super.
      def validate
        @errors = [] # Clear out previously generated errors.

        @errors << 'imported_by must always be provided' unless imported_by

        @errors << "bibnumber #{bibnumber} is invalid or could not be found" unless valid_bibnumber?

        @errors.concat(asset_set.errors) if asset_set&.invalid?
      end

      # Runs validations and returns a boolean value based on the success
      # or failure of the validations.
      #
      # @return [True] if no errors were generated
      # @return [False] if errors were generated
      def valid?
        validate
        errors.empty?
      end

      private

      # @return [ItemResource]
      def item
        return nil unless unique_identifier

        @item ||= find_item(unique_identifier)
      end

      # @return [String, nil]
      def bibnumber
        return unless descriptive_metadata

        @bibnumber ||= Array.wrap(descriptive_metadata[:bibnumber]).pick(:value)
      end

      # @return [Hash, nil]
      def marmite_metadata
        @marmite_metadata ||= begin
          MetadataExtractor::Marmite.new(url: Settings.marmite.url).descriptive_metadata(bibnumber)
        rescue MetadataExtractor::Marmite::Client::Error
          nil
        end
      end

      # @return [TrueClass, FalseClass]
      def valid_bibnumber?
        bibnumber.blank? ||
          (bibnumber.present? && MMSIDValidator::MMS_ID_VALIDITY_REGEX.match?(bibnumber) && marmite_metadata.present?)
      end

      def query_service
        Valkyrie::MetadataAdapter.find(:postgres).query_service
      end

      # Fetches ItemResource by unique_identifier, return nil if none present.
      def find_item(unique_identifier)
        query_service.custom_queries.find_by_unique_identifier(unique_identifier: unique_identifier)
      end

      # Creates a set of assets. If it fails to create any on asset, it returns the failure
      # and deletes all the assets that were created up to that point.
      #
      # @param [Array<ImportService::AssetsData>] assets_data
      # @param [Hash] additional_attrs to be passed in when creating each asset
      def batch_create_assets(assets_data, additional_attrs = {})
        created = []
        error = nil

        # Create all assets, break out of loop if there is an error making an asset.
        assets_data.each do |asset_data|
          result = asset_data.create_asset(**additional_attrs)

          if result.failure?
            error = failure(
              error: "Error while creating #{asset_data.filename}: #{result.failure[:error].to_s.humanize}",
              details: result.failure.fetch(:details, []),
              exception: result.failure[:exception]
            )
            break
          else
            created << result.value!
          end
        end

        if error.present?
          # if there's an error creating any Asset, fail and remove any loaded Assets
          delete_assets(created)
          error
        else
          Success(created)
        end
      end

      # Publishing an item.
      def publish_item(resource)
        PublishItem.new.call(id: resource.id, updated_by: imported_by) do |publish_result|
          publish_result.success { |published_item| Success(published_item) }
          publish_result.failure do |failure_hash|
            failure(
              prepend: 'Item was successfully created/updated. Please retry publishing. Publishing failed with the following error',
              **failure_hash
            )
          end
        end
      end

      # Deletes all the assets given.
      #
      # @param [<Array<AssetResource>]
      def delete_assets(assets)
        assets.each { |a| PurgeAsset.new.call(id: a.id) }
      end

      # Takes different failure params and returns a Failure object with three keys: error, details
      # and exception. The details array can contain some plain text formatting for display purposes. An
      # exception or change_set may not always be present.
      #
      # @param [String|Symbol] error main error message
      # @param [Array<String>] details list of more detailed error messages
      # @param [Valkyrie::ChangeSet] change_set containing validation errors
      # @param [Exception] exception
      # @param [String] prepend message to prefix main error message
      def failure(error: nil, details: [], change_set: nil, exception: nil, prepend: nil)
        error = error.to_s.humanize if error.is_a? Symbol
        error = "#{prepend}: #{error}" if prepend
        validation_errors = change_set.try(:errors).try(:full_messages)

        details.push(exception&.message) if exception
        details.concat(validation_errors) if validation_errors.present?

        if error
          # Display the details as nested below the error.
          details = details.map { |d| "\t#{d}" }.prepend(error)
        end

        Failure.new(error: :import_failed, details: details, exception: exception)
      end

      # Queries EZID to check if a given ark already exists.
      #
      # @return true if ark exists
      # @return false if ark does not exist
      def ark_exists?(ark)
        retries ||= 0
        Ezid::Identifier.find(ark)
        true
      rescue StandardError # EZID gem raises unexpected errors when ark isn't found.
        if (retries += 1) < 3 # Retrying request because EZID request fails even though ARK is present.
          sleep 1
          retry
        end

        false
      end

      # @return [Hash{Symbol->Array<String> | String}]
      def ocr_options
        { ocr_strategy: item_args[:ocr_strategy], ocr_language: ocr_language, viewing_direction: viewing_direction }
      end

      # @return [String, nil]
      def viewing_direction
        structural_metadata[:viewing_direction] || item&.structural_metadata&.viewing_direction
      end

      # @return [Array<String>]
      def ocr_language
        language_codes = extract_language_codes(descriptive_metadata[:language])

        return language_codes if language_codes.present?

        language_codes = extract_language_codes(ils_language_metadata) if bibnumber.present?

        return language_codes if language_codes.present? || item.blank?

        extract_language_codes(item.descriptive_metadata.language)
      end

      # @param data [Array]
      # @return [Array<String>]
      def extract_language_codes(data)
        Array.wrap(data).pluck(:value).flat_map { |l| ISO_639.find_by_english_name(l)&.first(2) }.compact_blank
      end

      # @return [Array]
      def ils_language_metadata
        return [] if bibnumber.blank?

        marmite_metadata[:language] || []
      end
    end
  end
end
