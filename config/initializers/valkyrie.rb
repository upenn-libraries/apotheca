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

  indexers = [ItemIndexer, DescriptiveMetadataIndexer]

  # To use the solr adapter you must add gem 'rsolr' to your Gemfile
  Valkyrie::MetadataAdapter.register(
    Valkyrie::Persistence::Solr::MetadataAdapter.new(
      connection: RSolr.connect(url: Settings.solr.url),
      resource_indexer: Valkyrie::Persistence::Solr::CompositeIndexer.new(*indexers),
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
    force_path_style: true,
    public: true # Adds public-read acl to all objects
  )

  preservation_copy_storage_config = Settings.preservation_copy_storage.to_h.merge(
    force_path_style: true,
    public: true # Adds public-read acl to all objects
  )

  derivatives_storage_config = Settings.derivative_storage.to_h.merge(
    force_path_style: true,
    public: true # Adds public-read acl to all objects
  )

  iiif_derivatives_storage_config = Settings.iiif_derivative_storage.to_h.merge(
    force_path_style: true,
    public: true # Adds public-read acl to all objects
  )

  Shrine.storages = {
    preservation: Shrine::Storage::S3.new(**preservation_storage_config),
    preservation_copy: Shrine::Storage::S3.new(**preservation_copy_storage_config),
    derivatives: Shrine::Storage::S3.new(**derivatives_storage_config),
    iiif_derivatives: Shrine::Storage::S3.new(**iiif_derivatives_storage_config)
  }

  Valkyrie::StorageAdapter.register(
    Valkyrie::Storage::Shrine.new(Shrine.storages[:preservation], identifier_prefix: 'preservation'),
    :preservation
  )

  Valkyrie::StorageAdapter.register(
    Valkyrie::Storage::Shrine.new(Shrine.storages[:preservation_copy], identifier_prefix: 'preservation_copy'),
    :preservation_copy
  )

  Valkyrie::StorageAdapter.register(
    Valkyrie::Storage::Shrine.new(
      Shrine.storages[:derivatives], nil, DerivativePathGenerator, identifier_prefix: 'derivatives'
    ), :derivatives
  )

  Valkyrie::StorageAdapter.register(
    Valkyrie::Storage::Shrine.new(
      Shrine.storages[:iiif_derivatives], nil, DerivativePathGenerator, identifier_prefix: 'iiif_derivatives'
    ), :iiif_derivatives
  )

  # Register custom queries for Solr adapter
  [ItemIndex].each do |solr_query_handler|
    Valkyrie::MetadataAdapter.find(:index_solr)
                             .query_service.custom_queries
                             .register_query_handler(solr_query_handler)
  end

  # Register custom queries for Postgres adapter
  [FindByUniqueIdentifier].each do |postgres_query_handler|
    Valkyrie::MetadataAdapter.find(:postgres)
                             .query_service.custom_queries
                             .register_query_handler(postgres_query_handler)
  end
end
