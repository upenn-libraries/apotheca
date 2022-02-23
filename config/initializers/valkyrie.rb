# frozen_string_literal: true
require 'valkyrie'
require 'shrine/storage/s3'
require 'valkyrie/shrine/checksum/s3'

Rails.application.config.to_prepare do
  ### METADATA ADAPTERS ###

  # To use the postgres adapter you must add `gem 'pg'` to your Gemfile
  Valkyrie::MetadataAdapter.register(
    Valkyrie::Persistence::Postgres::MetadataAdapter.new,
    :postgres
  )

  # To use the solr adapter you must add gem 'rsolr' to your Gemfile
  Valkyrie::MetadataAdapter.register(
    Valkyrie::Persistence::Solr::MetadataAdapter.new(
      connection: RSolr.connect(url: Settings.solr.url),
      # resource_indexer: Valkyrie::Persistence::Solr::CompositeIndexer.new(DescriptiveMetadataIndexer, TechnicalMetadataIndexer),
      write_only: true
    ),
    :index_solr
  )

  Valkyrie::MetadataAdapter.register(
    Valkyrie::AdapterContainer.new(
      persister: Valkyrie::Persistence::CompositePersister.new(
        Valkyrie::MetadataAdapter.find(:postgres).persister,
        Valkyrie::MetadataAdapter.find(:index_solr).persister
      ),
      query_service: Valkyrie::MetadataAdapter.find(:postgres).query_service
    ),
    :postgres_solr_persister
  )

  ### STORAGE ADAPTERS ###

  preservation_storage_config = Settings.preservation_storage.to_h.merge(
    region: 'us-east-1', # using default region
    force_path_style: true,
    public: true # Adds public-read acl to all objects
  )

  Shrine.storages = {
    preservation: Shrine::Storage::S3.new(preservation_storage_config)
  }

  Valkyrie::StorageAdapter.register(
    Valkyrie::Storage::Shrine.new(Shrine.storages[:preservation]), :preservation
  )
end
