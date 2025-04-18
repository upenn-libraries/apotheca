# frozen_string_literal: true

module ImportService
  # Represents an imported asset's metadata and file location.
  class AssetData
    include Dry::Monads[:result]

    attr_accessor :file_location, :metadata

    delegate :file, :checksum_sha256, to: :file_location

    def initialize(file_location: nil, checksum: nil, **metadata)
      @file_location = file_location
      @expected_checksum = checksum
      @metadata = metadata
    end

    def filename
      metadata[:filename]
    end

    # Checks if file is present in storage.
    def file?
      file_location.present?
    end

    # Create assets with the metadata and file information stored in this object. An asset is first
    # created without a file and then the asset is updated to add in the file. If an error occurs
    # while creating or updating the asset, any necessary clean up is done and then failure is returned.
    def create_asset(imported_by:, created_by: nil, **additional_attrs)
      CreateAsset.new.call(**resource_attributes, **additional_attrs, created_by: created_by || imported_by) do |result|
        result.success do |a|
          update_transaction.call(
            id: a.id, file: file, expected_checksum: @expected_checksum, updated_by: imported_by,
            ocr_strategy: additional_attrs[:ocr_strategy], ocr_language: additional_attrs[:ocr_language],
            viewing_direction: additional_attrs[:viewing_direction]
          ).tap do |update_result|
            # Delete asset if update failed, then return update_result value
            PurgeAsset.new.call(id: a.id) if update_result.failure?
          end
        end

        result.failure do |failure_hash|
          Failure(failure_hash)
        end
      end
    end

    # Update an existing asset with new metadata or file information stored in this object. Asset is
    # only updated if the file in storage has changed or if the metadata that is given is different
    # than the metadata already assigned.
    #
    # @param [AssetResource] asset to be updated
    def update_asset(asset:, imported_by:, **ocr_attributes)
      attributes = update_attrs(asset)

      return Success(asset) if attributes.empty? # Don't process an update if not necessary.

      update_transaction.call(
        id: asset.id,
        updated_by: imported_by,
        optimistic_lock_token: asset.optimistic_lock_token,
        **attributes,
        **ocr_attributes
      )
    end

    private

    # Returns attributes hash to be used in the update transaction. Only returns attributes that have changed.
    def update_attrs(asset)
      attributes = {}

      # Check if the asset preservation file needs to be updated
      attributes[:file] = file if file? && (asset.technical_metadata.sha256 != checksum_sha256)

      # Check if the metadata needs to be updated
      new_attr = resource_attributes

      attributes[:label] = new_attr[:label] if new_attr.key?(:label) && (asset.label != new_attr[:label])
      attributes[:annotations] = new_attr[:annotations] if new_attr.key?(:annotations) && asset.annotations.map(&:text).difference(new_attr[:annotations].pluck(:text))
      attributes[:transcriptions] = new_attr[:transcriptions] if new_attr.key?(:transcriptions) && asset.transcriptions.map(&:contents).difference(new_attr[:transcriptions].pluck(:contents))

      attributes
    end

    def update_transaction
      UpdateAsset.new.with_step_args(generate_derivatives: [skip: false])
    end

    # Make hash representation to send to the resource transactions.
    #
    # @return [Hash]
    def resource_attributes
      # In order to support deleting values, a check is necessary to ensure the key is present in the original
      # hash before setting the value. If a value was not provided we should not change that value at all.
      hash = { original_filename: metadata[:filename] }

      hash[:label]          = metadata[:label] if metadata.key?(:label)
      hash[:annotations]    = metadata[:annotation]&.map { |t| { text: t } } if metadata.key?(:annotation)

      if metadata.key?(:transcription)
        hash[:transcriptions] = metadata[:transcription]&.map { |t| { mime_type: 'text/plain', contents: t } }
      end

      hash
    end
  end
end
