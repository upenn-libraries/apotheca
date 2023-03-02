# frozen_string_literal: true

module ImportService
  # Class to process import jobs.
  class Process
    include Dry::Monads[:result]

    CREATE = 'create'
    UPDATE = 'update'
    IMPORT_ACTIONS = [CREATE, UPDATE].freeze

    attr_reader :unique_identifier, :action, :human_readable_name, :imported_by, :assets,
                :descriptive_metadata, :structural_metadata, :created_by,
                :repo, :errors

    # Initializes object to conduct import. For the time being this class will only import Items.
    #
    # @param [Hash] args passed in to create/update digital objects
    # @options opts [String] :action
    # @options opts [User] :imported_by
    # @options opts [String] :human_readable_name
    # @options opts [String] :unique_identifier
    # @options opts [AssetsLocation] :assets
    # @options opts [TrueClass, FalseClass] :publish
    # @options opts [Hash] :metadata  # gets mapped to descriptive_metadata
    # @options opts [Hash] :structural  # gets mapped to structural_metadata
    def initialize(args)
      args = args.deep_symbolize_keys

      # TODO: created_at, internal_notes, thumbnail_filename
      @action               = args[:action]&.downcase
      @unique_identifier    = args[:unique_identifier]
      @human_readable_name  = args[:human_readable_name]
      @imported_by          = args[:imported_by]
      @created_by           = args[:created_by]
      # @publish              = args.fetch(:publish, 'false').casecmp('true').zero?
      @descriptive_metadata = args.fetch(:metadata, {})
      @structural_metadata  = args.fetch(:structural, {})
      @assets               = args[:assets].blank? ? nil : AssetsData.new(**args[:assets])
      @errors               = []
    end

    # Validates that Item can be created or updated with all the information
    # given. These checks are meant to be lightweight checks that can be done
    # before starting the ingestion process. Returns false if there is
    # missing or incorrect information. Errors are stored in an instance variable.
    #
    # @return [True] if no errors were generated
    # @return [False] if errors were generated
    def valid?
      @errors << "\"#{action}\" is not a valid import action" unless IMPORT_ACTIONS.include?(action)

      if action == CREATE
        @errors << 'human_readable_name must be provided to create an object' unless human_readable_name
        @errors << 'assets must be provided to create an object' unless assets
        @errors << 'metadata must be provided to create an object' if descriptive_metadata.blank?

        if unique_identifier
          @errors << "\"#{unique_identifier}\" already belongs to an object. Cannot create new object with given unique identifier." if find_item(unique_identifier)
          @errors << "\"#{unique_identifier}\" is not minted" if unique_identifier && !ark_exists?(unique_identifier)
        end

        # If action is create, validate all filenames listed in structural metadata.
        if assets&.valid?
          missing = assets.missing_files
          @errors << "assets contains the following invalid filenames: #{missing.join(', ')}" if missing.present?
        end
      end

      if action == UPDATE
        if unique_identifier
          @errors << 'unique_identifier does not belong to an Item' unless find_item(unique_identifier)
        else
          @errors << 'unique_identifier must be provided when updating an Item'
        end
      end

      @errors.concat(assets.errors) if assets && !assets.valid?

      @errors << 'imported_by must always be provided' unless imported_by
      errors.empty?
    end

    # Runs process to import Item.
    #
    # @return [Dry::Monads::Success|Dry::Monads::Failure]
    def run
      return error_result(@errors) unless valid? # Validate before processing data.

      case action.downcase
      when CREATE
        create_item
      when UPDATE
        update_item
      end
    rescue StandardError => e
      # Honeybadger.notify(e) # Sending full error to Honeybadger.
      error_result [e.message]
    end

    private

    # TODO: think about using structured/unstructured instead of arranged/unarranged
    def create_item
      arranged_assets = assets.arranged.map do |asset|
        a = CreateAsset.new.call(created_by: created_by || imported_by, updated_by: imported_by, **asset).value!
        UpdateAsset.new.call(
          id: a.id,
          file: assets.file_for(asset[:original_filename]),
          updated_by: imported_by,
          original_filename: asset[:original_filename]
        ).value!
      end

      unarranged_assets = assets.unarranged.map do |asset|
        a = CreateAsset.new.call(created_by: created_by || imported_by, updated_by: imported_by, **asset).value!
        UpdateAsset.new.call(
          id: a.id,
          file: assets.file_for(asset[:original_filename]),
          updated_by: imported_by,
          original_filename: asset[:original_filename]
        ).value!
      end
      # TODO: if asset creation fails, we need a way to clean it up
      # TODO: persisted assets in batches might be more efficient.

      # Create item with assets
      item_attributes = {
        human_readable_name: human_readable_name,
        created_by: created_by || imported_by,
        updated_by: imported_by,
        descriptive_metadata: descriptive_metadata,
        structural_metadata: structural_metadata,
        asset_ids: arranged_assets.map(&:id) + unarranged_assets.map(&:id)
      }
      item_attributes[:structural_metadata][:arranged_asset_ids] = arranged_assets.map(&:id)

      CreateItem.new.call(item_attributes)
    end

    def update_item
      find_item(unique_identifier)
    end

    # Fetches ItemResource by unique_identifier, return nil if none present.
    def find_item(unique_identifier)
      query_service = Valkyrie::MetadataAdapter.find(:postgres).query_service
      query_service.custom_queries.find_by_unique_identifier(unique_identifier: unique_identifier)
    end

    # @param [Array] errors
    def error_result(errors)
      Failure.new(error: :import_failed, details: errors)
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
