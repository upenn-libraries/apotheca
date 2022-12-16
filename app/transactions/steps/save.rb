# frozen_string_literal: true

module Steps
  # Persists ChangeSet in Postgres and Solr.
  class Save
    include Dry::Monads[:result]

    def call(change_set:, **options)
      resource = change_set.sync

      begin
        saved_resource = persister.save(resource: resource)
        Success(resource: saved_resource, **options)
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
