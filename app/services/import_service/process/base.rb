# frozen_string_literal: true

module ImportService
  class Process
    # Base class for processing imports that includes logic that is required for
    # all imports. Import classes should inherit from this class.
    class Base
      include Dry::Monads[:result]

      attr_reader :errors, :imported_by, :descriptive_metadata, :structural_metadata,
                  :assets, :unique_identifier, :human_readable_name, :internal_notes

      # Initializes object to conduct import. For the time being this class will only import Items.
      #
      # @param [String] :imported_by
      # @param [String] :unique_identifier
      # @param [String] :human_readable_name
      # @param [Array<String>] :internal_notes
      # @param [Hash] :metadata  # gets mapped to descriptive_metadata
      # @param [Hash] :structural  # gets mapped to structural_metadata
      # @param [AssetsLocation] :assets
      def initialize(**args)
        @imported_by          = args[:imported_by]
        @unique_identifier    = args[:unique_identifier]
        @human_readable_name  = args[:human_readable_name]
        @internal_notes       = args[:internal_notes]
        @descriptive_metadata = args.fetch(:metadata, {})
        @structural_metadata  = args.fetch(:structural, {})
        @assets               = args[:assets].blank? ? nil : AssetsData.new(**args[:assets])
        @errors               = []
      end

      # Validates that import has all the necessary information. These checks are meant
      # to be lightweight checks that can be done before starting the import process.
      # Errors are stored in an instance variable. Subclasses should override this method
      # and call super.
      def validate
        @errors = [] # Clear out previously generated errors.

        @errors << 'imported_by must always be provided' unless imported_by

        @errors.concat(assets.errors) if assets && !assets.valid?
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

      # Fetches ItemResource by unique_identifier, return nil if none present.
      def find_item(unique_identifier)
        query_service = Valkyrie::MetadataAdapter.find(:postgres).query_service
        query_service.custom_queries.find_by_unique_identifier(unique_identifier: unique_identifier)
      end

      # Takes different failure params and returns a Failure object with two keys: error, details.
      #
      # @param [Array] error
      def failure(error: nil, details: [], change_set: nil, exception: nil)
        error = error.try(:to_s).try(:humanize)
        validation_errors = change_set.try(:errors).try(:full_messages)

        details.push([error, exception.message].compact.join(': ')) if exception
        details.concat(validation_errors.map { |e| [error, e].compact.join(': ') }) if validation_errors.present?

        Failure.new(error: :import_failed, details: details)
      end
    end
  end
end
