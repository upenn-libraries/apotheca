# frozen_string_literal: true

module Solr
  # build a solr query hash from expected parameters
  class QueryBuilder
    def initialize(params:, defaults:, mapper: nil)
      @query = {}
      @params = mapper ? map_params(params) : params # map params if mapper provided
      @defaults = defaults
    end

    def map_params(params)
      # TODO: replace values using mapper module?
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
      filters = @params['filters']&.to_unsafe_h || {}
      filters = filters.delete_if { |k,v| v.blank? }
      # TODO use querymap to ensure only configured fields are used?
      # filters = filters.delete_if { |k, v| !k.in?(Solr::QueryMaps::Item::Mapping::Filter.constants.map(&downcase) || v.blank? }
      all_filters = @defaults[:fq].merge filters.to_h
      all_filters.map do |fq, v|
        fq_condition field: fq, values: v
      end.join(' AND ') # use AND for all field values (have this attribute AND that attribute)
    end

    # compose Sort param
    def sort
      sort_field = @params['sort_field']
      sort_direction = @params['sort_direction']
      sort_field = 'score' if sort_field.blank?
      sort_direction = 'asc' if sort_direction.blank?
      "#{sort_field} #{sort_direction}"
    end

    private

    # @param [String] field
    # @param [String, Array] values
    # @return [String]
    def fq_condition(field:, values:)
      Array.wrap(values).map do |value|
        "#{field}: \"#{value}\""
      end.join(' OR ').insert(0, '(').insert(-1, ')') # use OR for particular field values (this OR that collection)
    end

    def map_field(entity:, type:, field:)
      mapper = Solr::QueryMaps.const_get entity.to_s.titleize
      return 'no mapper' unless mapper

      map = mapper::Mapping.const_get type.to_s.titleize
      return unless map

      map.const_get field.to_s.titleize
    end

  end
end
