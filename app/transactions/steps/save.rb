# frozen_string_literal: true

module Steps
  # Persists ChangeSet in Postgres and Solr.
  class Save
    include Dry::Monads[:result]

    def call(change_set)
      resource = change_set.sync

      begin
        saved_resource = persister.save(resource: resource)
        Success(saved_resource)
      rescue StandardError => e
        Failure[:error_saving_resource, e]
      end
    end

    private

    def persister
      Valkyrie::MetadataAdapter.find(:postgres_solr_persister).persister
    end
  end
end
