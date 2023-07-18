# frozen_string_literal: true

module Steps
  # Updating metadata in EZID record.
  class UpdateArkMetadata
    include Dry::Monads[:result]

    def call(resource)
      return Success(resource) if Settings.skip_ezid_metadata_update

      # TODO: This needs to be updated to use the new metadata schema.
      erc_metadata = {
        # erc_who: resource.descriptive_metadata.name.join('; '),
        erc_what: resource.descriptive_metadata.title.join('; '),
        erc_when: resource.descriptive_metadata.date.join('; ')
      }
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
