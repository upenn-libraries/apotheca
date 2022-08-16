# frozen_string_literal: true

# query class for searching, filtering and sorting over ItemResources
class ItemIndex
  DEFAULT_FQ = '' # ensure we are returning only ItemResources

  def self.queries
    [:item_index]
  end

  attr_reader :query_service

  delegate :connection, to: :query_service # RSolr
  delegate :resource_factory, to: :query_service

  # @param [Object] query_service
  def initialize(query_service:)
    @query_service = query_service
  end

  # search for Resources based on parameters
  def item_index(parameters:)
    resources_from parameters: parameters
  end

  private

  # @param [Hash] parameters
  def solr_query(parameters:)
    { q: parameters[:keyword],
      rows: parameters[:rows],
      sort: solr_sort_from(sort_field: parameters[:sort_field],
                           sort_direction: parameters[:sort_direction]),
      fq: solr_fq_from(field: parameters[:filter_field],
                       values: parameters[:filter_values]) }
  end

  # compose FilterQuery param
  # @param [String] field
  # @param [String] values
  def solr_fq_from(field:, values:)
    'internal_resource_tsim:ItemResource'
    # TODO: include DEFAULT_FQ, support ANDing?
  end

  # compose Sort param
  def solr_sort_from(sort_field:, sort_direction:)
    sort_field ||= 'score'
    sort_direction ||= 'asc'
    "#{sort_field} #{sort_direction}"
  end

  # get Solr response
  def response(solr_query:)
    connection.get('select', params: solr_query)
  end

  # convert Solr response into Resource objects
  def resources_from(parameters:)
    response = response solr_query: solr_query(parameters: parameters)
    docs = response.dig('response', 'docs')
    docs.map { |d| resource_factory.to_resource(object: d) }
  end
end
