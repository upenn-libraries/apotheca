# frozen_string_literal: true

# query class for searching, filtering and sorting over ItemResources
class ItemIndex
  DEFAULT_FQ = { internal_resource_tsim: ['ItemResource'] }.freeze # ensure we are returning only ItemResources
  PERMITTED_FILTERS = ['collection_ssim'].freeze

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
  def item_index(parameters:)
    resources_from parameters: parameters
  end

  # get Solr response
  def response(solr_query:)
    connection.get('select', params: solr_query)
  end

  # convert Solr response into Resource objects
  # @param [Object] parameters
  def resources_from(parameters:)
    query_builder = Solr::QueryBuilder.new params: parameters, defaults: { fq: DEFAULT_FQ }
    response = response solr_query: query_builder.solr_query
    docs = response.dig('response', 'docs')
    items = docs.map { |d| resource_factory.to_resource(object: d) }
    facets = response.dig('facet_counts', 'facet_fields')
    Solr::ResponseContainer.new documents: items, facet_data: facets
  end
end
