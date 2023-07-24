# frozen_string_literal: true

module Steps
  # Updating metadata in EZID record.
  class UpdateArkMetadata
    include Dry::Monads[:result]

    def call(resource)
      return Success(resource) if Settings.skip_ezid_metadata_update

      # TODO: This needs to use the metadata that is pulled from the ILS.
      erc_metadata = {
        '_profile' => 'dc',
        'dc.creator' => resource.descriptive_metadata&.name&.pluck(:value)&.join('; '),
        'dc.title' => resource.descriptive_metadata&.title&.pluck(:value)&.join('; '),
        'dc.publisher' => resource.descriptive_metadata&.publisher&.pluck(:value)&.join('; '),
        'dc.date' => resource.descriptive_metadata&.date&.pluck(:value)&.join('; '),
        'dc.type' => resource.descriptive_metadata&.item_type&.pluck(:value)&.join('; ')
      }.compact_blank

      begin
        # NOTE: EZID library retries requests twice before raising an error.
        Ezid::Identifier.modify(resource.unique_identifier, erc_metadata)
        Success(resource)
      rescue StandardError => e
        Failure(error: :failed_to_update_ezid_metadata, exception: e)
      end
    end
  end
end
