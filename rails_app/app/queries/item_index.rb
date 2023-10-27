# frozen_string_literal: true

# Query class for searching, filtering and sorting over ItemResources via Solr
class ItemIndex
  DEFAULT_FQ = { internal_resource: ['ItemResource'] }.freeze # ensure we are returning only ItemResources
  DEFAULT_SORT = { field: 'created_at', direction: 'desc' }.freeze
  MAPPER = Solr::QueryMaps::Item

  attr_reader :query_service

  delegate :connection, to: :query_service # RSolr
  delegate :resource_factory, to: :query_service

  def self.queries
    [:item_index]
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
    Solr::QueryBuilder.new(params: parameters, defaults: { fq: DEFAULT_FQ, sort: DEFAULT_SORT }, mapper: MAPPER)
                      .solr_query
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
