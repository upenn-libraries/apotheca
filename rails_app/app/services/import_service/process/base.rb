# frozen_string_literal: true

module ImportService
  class Process
    # Base class for processing imports that includes logic that is required for
    # all imports. Import classes should inherit from this class.
    class Base
      include Dry::Monads[:result]

      attr_reader :errors, :imported_by, :descriptive_metadata, :structural_metadata,
                  :asset_set, :unique_identifier, :human_readable_name, :internal_notes

      # Initializes object to conduct import. For the time being this class will only import Items.
      #
      # @param [String] :imported_by
      # @param [String] :unique_identifier
      # @param [String] :human_readable_name
      # @param [Array<String>] :internal_notes
      # @param [Hash] :metadata  # gets mapped to descriptive_metadata
      # @param [Hash] :structural  # gets mapped to structural_metadata
      def initialize(**args)
        @imported_by          = args[:imported_by]
        @unique_identifier    = args[:unique_identifier]
        @human_readable_name  = args[:human_readable_name]
        @internal_notes       = args[:internal_notes]
        @descriptive_metadata = args.fetch(:metadata, {})
        @structural_metadata  = args.fetch(:structural, {})
        @errors               = []
      end

      # Validates that import has all the necessary information. These checks are meant
      # to be lightweight checks that can be done before starting the import process.
      # Errors are stored in an instance variable. Subclasses should override this method
      # and call super.
      def validate
        @errors = [] # Clear out previously generated errors.

        @errors << 'imported_by must always be provided' unless imported_by

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
            error = failure(**result.failure)
            # Adding additional error message
            error = failure(
              error: "Following error(s) raised when generating #{asset_data.filename}:",
              details: error.failure[:details]
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

      # Deletes all the assets given.
      #
      # @param [<Array<AssetResource>]
      def delete_assets(assets)
        assets.each { |a| DeleteAsset.new.call(id: a.id) }
      end

      # Takes different failure params and returns a Failure object with two keys: error, details. The details
      # array can contain some plain text formatting for display purposes.
      #
      # @param [String|Symbol] error
      # @param [Array<String>] details
      # @param [Valkyrie::ChangeSet] change_set
      # @param [Exception] exception
      def failure(error: nil, details: [], change_set: nil, exception: nil)
        error = error.try(:to_s).try(:humanize)
        validation_errors = change_set.try(:errors).try(:full_messages)

        details.push(exception&.message) if exception
        details.concat(validation_errors) if validation_errors.present?

        if error
          # Display the details as nested below the error.
          details = details.map { |d| "\t" + d }.prepend(error)
        end

        Failure.new(error: :import_failed, details: details)
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
