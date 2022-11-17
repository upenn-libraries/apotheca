# frozen_string_literal: true

module Solr
  # build a solr query hash from expected parameters
  class QueryBuilder
    attr_accessor :params, :mapper

    def initialize(params:, defaults:, mapper:)
      @query = {}
      @params = params
      @defaults = defaults
      @mapper = mapper
    end

    # @return [Hash]
    def solr_query
      { q: @params[:keyword],
        rows: @params[:rows],
        sort: sort,
        fq: fq }
    end

    # @param [String] query
    # @param [Object] field
    def search(query:, field: nil)
      return query unless field

      # TODO: handle fielded search?
    end

    # compose FilterQuery param
    # @return [String]
    def fq
      filters = @params['filter']&.to_unsafe_h || {}
      filters = filters.delete_if { |k, v| v.blank? || !k.to_sym.in?(Solr::QueryMaps::Item::Filter.fields) }
      all_filters = @defaults[:fq].merge filters.to_h
      all_filters.filter_map do |field, v|
        fq_condition field: field, values: v
      end.join(' AND ') # use AND for all field values (have this attribute AND that attribute)
    end

    # compose Sort param
    def sort
      sort_field = @params.dig :sort, :field
      sort_direction = @params.dig :sort, :direction
      sort_field = 'score' if sort_field.blank?
      sort_field = map type: :sort, field: sort_field
      sort_direction = 'asc' if sort_direction.blank?
      "#{sort_field} #{sort_direction}"
    end

    private

    def map(type:, field:)
      mapper_type = mapper.const_get(type.to_s.titleize)
      return nil unless mapper_type

      mapper_type.public_send field
    end

    # @param [String] field
    # @param [String, Array] values
    # @return [String]
    def fq_condition(field:, values:)
      solr_field = map type: :filter, field: field
      return nil unless solr_field

      Array.wrap(values).map do |value|
        "#{solr_field}: \"#{value}\""
      end.join(' OR ').insert(0, '(').insert(-1, ')') # use OR for particular field values (this OR that collection)
    end
  end
end
