# frozen_string_literal: true

module SolrQueries
  # Query class for searching, filtering and sorting over ItemResources via Solr
  # Also note that search and facet field configuration also resides in the solrconfig.xml file
  class ItemIndex
    DEFAULT_FQ = { internal_resource: ['ItemResource'] }.freeze # ensure we are returning only ItemResources
    DEFAULT_SORT = { field: 'created_at', direction: 'desc' }.freeze
    MAPPER = Solr::QueryMaps::Item

    attr_reader :query_service

    delegate :connection, to: :query_service # RSolr
    delegate :resource_factory, to: :query_service

    def self.queries
      %i[item_index item_index_all]
    end

    # @param [Object] query_service
    def initialize(query_service:)
      @query_service = query_service
    end

    # search for Resources based on parameters
    # @param [ActionController::Parameters] parameters
    # @return [Solr::ResponseContainer]
    def item_index(parameters:)
      query = solr_query(parameters: parameters)
      response = response(solr_query: query)
      build_response_container response: response, search_params: parameters, query: query
    end

    # recursively retrieve all resources based on parameters and solr cursor mark
    # @param [ActionController::Parameters] parameters
    # @param [Array<Hash>] documents
    # @param [String] cursor_mark
    # @return [Solr::ResponseContainer]
    def item_index_all(parameters:, documents: [], cursor_mark: '*')
      query = solr_query(parameters: parameters.merge(rows: MAPPER::MAX_BULK_EXPORT_ROWS, cursorMark: cursor_mark))
      response = response(solr_query: query)

      documents += response.dig('response', 'docs')
      if cursor_mark == response['nextCursorMark']
        return Solr::ResponseContainer.new(documents: build_item_presenters(solr_documents: documents),
                                           facet_data: response.dig('facet_counts', 'facet_fields'),
                                           search_params: parameters, query: query,
                                           total_count: response.dig('response', 'numFound'))
      end

      item_index_all(parameters: parameters, documents: documents, cursor_mark: response['nextCursorMark'])
    end

    # @param [RSolr::HashWithResponse] response
    # @param [ActionController::Parameters] search_params
    # @param [Hash] query
    # @return [Solr::ResponseContainer]
    def build_response_container(response:, search_params:, query:)
      docs = response.dig('response', 'docs')
      Solr::ResponseContainer.new(
        documents: build_item_presenters(solr_documents: docs),
        facet_data: response.dig('facet_counts', 'facet_fields'),
        search_params: search_params,
        total_count: response.dig('response', 'numFound'),
        query: query
      )
    end

    # get Solr response
    # @param [Hash] solr_query
    # @return [RSolr::HashWithResponse]
    def response(solr_query:)
      connection.get('select', params: solr_query)
    end

    # Use Solr::QueryBuilder to compose Solr query from params
    # @param [ActionController::Parameters] parameters
    # @return [Hash]
    def solr_query(parameters:)
      Solr::QueryBuilder.new(params: parameters,
                             defaults: { fq: DEFAULT_FQ, sort: DEFAULT_SORT },
                             mapper: MAPPER).solr_query
    end

    # @param [Array] solr_documents
    def build_item_presenters(solr_documents:)
      solr_documents.map do |d|
        resource = resource_factory.to_resource(object: d)
        # Get ILS metadata as a Hash by pulling it out of the Solr doc and parsing it.
        ils_metadata = d[DescriptiveMetadataIndexer::ILS_METADATA_JSON_FIELD.to_s]
        ils_metadata = JSON.parse(ils_metadata) if ils_metadata
        ItemResourcePresenter.new object: resource, ils_metadata: ils_metadata
      end
    end
  end
end
