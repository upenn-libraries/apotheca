# frozen_string_literal: true

module Steps
  # Persists ChangeSet in Postgres and Solr.
  class Save
    include Dry::Monads[:result]

    def call(change_set)
      resource = change_set.sync
      saved_resource = persister.save(resource: resource)
      Success(saved_resource)
    end

    private

    def persister
      Valkyrie::MetadataAdapter.find(:postgres_solr_persister).persister
    end
  end
end
