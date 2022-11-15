# frozen_string_literal: true

module Solr
  # build a solr query hash from expected parameters
  class QueryBuilder
    def initialize(params:, defaults:, permitted_fq: [])
      @query = {}
      @params = params
      @defaults = defaults
      @permitted_fq = permitted_fq
    end

    # @return [Hash]
    def solr_query
      { q: @params[:keyword],
        rows: @params[:rows],
        sort: solr_sort_from(sort_field: @params[:sort_field].to_s,
                             sort_direction: @params[:sort_direction].to_s),
        fq: solr_fq_from(filters: @params[:filters]) }
    end

    # compose FilterQuery param
    # @param [ActionController::Parameters] filters
    # @return [String]
    def solr_fq_from(filters:)
      filters = filters&.to_unsafe_h || {}
      filters = filters.delete_if { |k, v| !k.in?(@permitted_fq) || v.blank? }
      all_filters = @defaults[:fq].merge filters.to_h
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
  end
end
