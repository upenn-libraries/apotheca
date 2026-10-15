# frozen_string_literal: true

module Resource
  module Steps
    # Save ChangeSet.
    class Save
      include Dry::Monads[:result]

      # Persists ChangeSet in Postgres and Solr.
      #
      # @param change_set [Valkyrie::ChangeSet]
      def call(change_set)
        resource = change_set.sync

        begin
          saved_resource = persister.save(resource: resource)
          Success(saved_resource)
        rescue StandardError => e
          Failure(error: :error_saving_resource, exception: e, change_set: change_set)
        end
      end

      private

      def persister
        Valkyrie::MetadataAdapter.find(:postgres_solr_persister).persister
      end
    end
  end
end
