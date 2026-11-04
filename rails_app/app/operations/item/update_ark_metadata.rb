# frozen_string_literal: true

module Item
  # Operation to update ark metadata of an item
  class UpdateArkMetadata < Operation
    # @param id [String] UUID of Item being updated
    def call(id:)
      resource = step find_item(id)
      step update_ark_metadata(resource: resource)

      resource
    end

    # @param resource [ItemResource]
    def update_ark_metadata(resource:)
      return Success(resource) if Settings.ezid_metadata_update.skip

      # NOTE: EZID library retries requests twice before raising an error.
      Ezid::Identifier.modify(resource.unique_identifier, dc_metadata(resource))
      Success(resource)
    rescue StandardError => e
      Failure(error: :failed_to_update_ezid_metadata, exception: e)
    end

    # Return dublin core metadata
    #
    # @param resource [ItemResource]
    # @return [Hash{String->String}]
    def dc_metadata(resource)
      # Using presenter that contains ILS metadata and resource metadata.
      descriptive_metadata = resource.presenter.descriptive_metadata

      metadata_profile = { '_profile' => 'dc' }

      metadata = {
        'dc.creator' => descriptive_metadata.name,
        'dc.title' => descriptive_metadata.title,
        'dc.publisher' => descriptive_metadata.publisher,
        'dc.date' => descriptive_metadata.date,
        'dc.type' => descriptive_metadata.item_type
      }.transform_values { |metadata| metadata&.pluck(:value)&.join('; ') }
       .compact_blank

      metadata_profile.merge(metadata)
    end
  end
end
