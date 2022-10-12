# frozen_string_literal: true

module Steps
  class UpdateArkMetadata
    include Dry::Monads[:result]

    def call(resource)
      # TODO: This is the metadata that we use now, but we should probably revisit.
      erc_metadata = {
        erc_who: resource.descriptive_metadata.creator.join('; '),
        erc_what: resource.descriptive_metadata.title.join('; '),
        erc_when: resource.descriptive_metadata.date.join('; ')
      }
      begin
        # Note: EZID library retries requests twice before raising an error.
        Ezid::Identifier.modify(resource.unique_identifier, erc_metadata)
        Success(resource)
      rescue => e
        Failure(:failed_to_update_ezid_metadata)
      end
    end
  end
end
