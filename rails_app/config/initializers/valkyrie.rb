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
  solr_url = URI.parse(Settings.solr.url)
  solr_url.user = Settings.solr.user
  solr_url.password = Settings.solr.password

  Valkyrie::MetadataAdapter.register(
    Valkyrie::Persistence::Solr::MetadataAdapter.new(
      connection: RSolr.connect(url: solr_url.to_s),
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

  Shrine.storages = {
    preservation: Shrine::Storage::S3.new(**Settings.preservation_storage),
    preservation_copy: Shrine::Storage::S3.new(**Settings.preservation_copy_storage),
    derivatives: Shrine::Storage::S3.new(**Settings.derivative_storage),
    iiif_derivatives: Shrine::Storage::S3.new(**Settings.iiif_derivative_storage),
    iiif_manifests: Shrine::Storage::S3.new(**Settings.iiif_manifest_storage)
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

  Valkyrie::StorageAdapter.register(
    Valkyrie::Storage::Shrine.new(
      Shrine.storages[:iiif_manifests], nil, DerivativePathGenerator, identifier_prefix: 'iiif_manifests'
    ), :iiif_manifests
  )

  # Register custom queries for Solr
  [ItemIndex, ItemIlsMetadata].each do |custom_query|
    Valkyrie::MetadataAdapter.find(:index_solr)
                             .query_service.custom_queries
                             .register_query_handler(custom_query)
  end

  # Register custom queries for Postgres adapter
  [FindByUniqueIdentifier].each do |postgres_query_handler|
    Valkyrie::MetadataAdapter.find(:postgres)
                             .query_service.custom_queries
                             .register_query_handler(postgres_query_handler)
  end

  ### VALKYRIE OVERRIDES ###

  # Requiring full iso8601 timestamp with offset in order to deserialize a string to a DateTime object.
  require 'valkyrie_extensions/date_time_json_value'
  Valkyrie::Persistence::Shared::JSONValueMapper::DateValue.singleton_class.send(
    :prepend, ValkyrieExtensions::DateTimeJSONValue
  )
end
