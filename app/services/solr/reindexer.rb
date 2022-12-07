# frozen_string_literal: true

module Solr
  # Reindexer, appropriated from Figgy
  class Reindexer
    INDEXED_RESOURCES = [ItemResource, AssetResource].freeze

    def self.reindex_all(logger: Logger.new($stdout), wipe: false, batch_size: 500, solr_adapter: :index_solr)
      new(
        solr_adapter: Valkyrie::MetadataAdapter.find(solr_adapter),
        query_service: Valkyrie::MetadataAdapter.find(:postgres).query_service,
        logger: logger,
        wipe: wipe,
        batch_size: batch_size
      ).reindex_all
    end

    attr_reader :solr_adapter, :query_service, :logger, :wipe, :batch_size

    def initialize(solr_adapter:, query_service:, logger:, wipe: false, batch_size: 500)
      @solr_adapter = solr_adapter
      @query_service = query_service
      @logger = logger
      @wipe = wipe
      @batch_size = batch_size
    end

    def reindex_all(resources: INDEXED_RESOURCES)
      wipe_records if wipe
      logger.info "Reindexing all records (for resources #{resources.to_sentence})"
      FilteredIndexer.new(indexer: self, resources: resources).index!
      logger.info 'Done'
    end

    def wipe_records
      logger.info 'Clearing Solr'
      solr_adapter.persister.wipe!
    end

    # Indexer class supporting filtering by resource type
    class FilteredIndexer
      attr_reader :indexer, :resources

      delegate :solr_adapter, :query_service, :logger, :batch_size, to: :indexer

      def initialize(indexer:, resources:)
        @indexer = indexer
        @resources = resources
      end

      def index!
        index_individually = []
        all_resources.each do |resources|
          resources.each_slice(batch_size) do |records|
            multi_index_persist(records)
          rescue RSolr::Error::ConnectionRefused, RSolr::Error::Http
            index_individually += records
          end
        end
        run_individual_retries(index_individually)
        solr_adapter.connection.commit
      end

      def run_individual_retries(records)
        logger.info "Reindexing #{records.count} individually due to errors during batch indexing"
        records.each { |record| single_index(record) }
      end

      def single_index(record)
        single_index_persist(record)
      rescue RSolr::Error::ConnectionRefused, RSolr::Error::Http => e
        logger.error("Could not index #{record.id} due to #{e.class}")
        # Honeybadger.notify(e, context: { record_id: record.id })
      end

      def multi_index_persist(records)
        solr_adapter.persister.save_all(resources: records)
      end

      def single_index_persist(record)
        solr_adapter.persister.save(resource: record, external_resource: true)
      end

      def all_resources
        resources.map do |resource|
          query_service.find_all_of_model(model: resource)
        end
      end
    end
  end
end
