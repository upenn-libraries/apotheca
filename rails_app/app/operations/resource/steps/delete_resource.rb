# frozen_string_literal: true

module Resource
  module Steps
    # Deletes resource.
    class DeleteResource
      include Dry::Monads[:result]

      # @param resource [Valkyrie::Resource]
      def call(resource)
        persister.delete(resource: resource)
        Success(resource)
      rescue StandardError => e
        Failure(error: :failed_to_delete_resource, exception: e)
      end

      private

      def persister
        Valkyrie::MetadataAdapter.find(:postgres_solr_persister).persister
      end
    end
  end
end
