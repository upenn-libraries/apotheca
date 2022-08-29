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

  private

  # @param [ActionController::Parameters] parameters
  # @return [Hash]
  def solr_query(parameters:)
    { q: parameters[:keyword],
      rows: parameters[:rows],
      sort: solr_sort_from(sort_field: parameters[:sort_field].to_s,
                           sort_direction: parameters[:sort_direction].to_s),
      fq: solr_fq_from(filters: parameters[:filters]) }
  end

  # compose FilterQuery param
  # @param [ActionController::Parameters] filters
  # @return [String]
  def solr_fq_from(filters:)
    filters = filters&.to_unsafe_h || {}
    filters = filters.delete_if { |k, v| !k.in?(PERMITTED_FILTERS) || v.blank? }
    all_filters = DEFAULT_FQ.merge filters.to_h
    all_filters.map do |fq, v|
      solr_fq_condition field: fq, values: v
    end.join(' AND ') # use AND for all field values (have this attribute AND that attribute)
  end

  # @param [String] field
  # @param [String, Array] values
  # @return [String]
  def solr_fq_condition(field:, values:)
    Array.wrap(values).map do |value|
      "#{field}: \"#{value}\""
    end.join(' OR ').insert(0, '(').insert(-1, ')') # use OR for particular field values (this OR that collection)
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
    items = docs.map { |d| resource_factory.to_resource(object: d) }
    facets = response.dig('facet_counts', 'facet_fields')
    ItemsContainer.new items: items, facet_data: facets
  end

  # Container for response
  class ItemsContainer
    attr_reader :items, :facets

    def initialize(items:, facet_data:)
      @items = items
      @facets = facets_to_hash(facet_data: facet_data)
    end

    private

    def facets_to_hash(facet_data:)
      facet_data.transform_values do |v|
        v.each_slice(2).map do |a, b|
          ["#{a} (#{b})", a]
        end
      end
    end
  end
end
