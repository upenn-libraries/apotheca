# frozen_string_literal: true

module Steps
  # Enqueue job to update metadata in EZID record.
  class EnqueueArkMetadataUpdate
    include Dry::Monads[:result]

    def call(resource)
      UpdateArkMetadataJob.perform_async(resource.id.to_s)
    end
  end
end
