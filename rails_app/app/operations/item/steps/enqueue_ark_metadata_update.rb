# frozen_string_literal: true

module Item
  module Steps
    # Asynchronously update EZID metadata.
    class EnqueueArkMetadataUpdate
      include Dry::Monads[:result]

      # Enqueue job to update metadata in EZID record.
      #
      # @param resource [Valkyrie::Resource]
      def call(resource)
        if UpdateArkMetadataJob.perform_async(resource.id.to_s)
          Success(resource)
        else
          Failure(error: :error_enqueuing_job)
        end
      end
    end
  end
end
