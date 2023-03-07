# frozen_string_literal: true

# query class for searching, filtering and sorting over ItemResources
class ItemIndex
  DEFAULT_FQ = { internal_resource: ['ItemResource'] }.freeze # ensure we are returning only ItemResources
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
  def item_index(parameters:, rows:)
    query = solr_query(parameters: parameters)
    response = response(solr_query: query)
    build_response_container response: response, search_params: parameters, query: query, rows: rows
  end

  # @param [RSolr::HashWithResponse] response
  # @param [ActionController::Parameters] search_params
  # @param [Hash] query
  # @return [Solr::ResponseContainer]
  def build_response_container(response:, search_params:, query:, rows:)
    docs = response.dig('response', 'docs')
    items = docs.map { |d| resource_factory.to_resource(object: d) }
    Solr::ResponseContainer.new(
      documents: items,
      facet_data: response.dig('facet_counts', 'facet_fields'),
      search_params: search_params,
      total_count: response.dig('response', 'numFound'),
      query: query,
      rows: rows
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
    Solr::QueryBuilder.new(params: parameters, defaults: { fq: DEFAULT_FQ }, mapper: MAPPER).solr_query
  end
end
