# frozen_string_literal: true

# query class for searching, filtering and sorting over ItemResources
class ItemIndex
  DEFAULT_FQ = { internal_resource_tsim: ['ItemResource'] }.freeze # ensure we are returning only ItemResources

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

  private

  # @param [ActionController::Parameters] parameters
  # @return [Hash]
  def solr_query(parameters:)
    { q: parameters[:keyword],
      rows: parameters[:rows],
      sort: solr_sort_from(sort_field: parameters[:sort_field].to_s,
                           sort_direction: parameters[:sort_direction].to_s),
      fq: solr_fq_from(field: parameters[:filter_field].to_s,
                       values: Array.wrap(parameters[:filter_values])) }
  end

  # compose FilterQuery param
  # @param [String] field
  # @param [Array] values
  # @return [Array]
  def solr_fq_from(field:, values:)
    filters = DEFAULT_FQ.merge field => values
    filters.map do |fq, v|
      v.map do |value|
        "#{fq}: #{value}"
      end.join(' OR ')
    end
  end

  # compose Sort param
  # @param [String] sort_field
  # @param [String] sort_direction
  def solr_sort_from(sort_field:, sort_direction:)
    sort_field = 'score' if sort_field.blank?
    sort_direction = 'asc' if sort_direction.blank?
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
