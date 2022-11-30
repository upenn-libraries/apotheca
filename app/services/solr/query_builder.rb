# frozen_string_literal: true

module Solr
  # build a solr query hash from expected parameters
  # solr docs: https://solr.apache.org/guide/solr/latest/query-guide/standard-query-parser.html#standard-query-parser-parameters
  class QueryBuilder
    attr_accessor :params, :mapper, :defaults

    # @param [ActionController::Parameters] params
    # @param [Hash] defaults
    # @param [Module<Solr::QueryMaps::Item>] mapper
    def initialize(params:, defaults:, mapper:)
      @params = params
      @defaults = defaults
      @mapper = mapper
    end

    # @return [Hash]
    def solr_query
      { q: search,
        rows: params[:rows],
        sort: sort,
        fq: fq }
    end

    # return q param for solr query
    # e.g., subject_tsim: "subject" AND title_tsim: "ancient"
    # "fielded" queries should be ANDed
    # e.g., (+subject_tsim: 'Metallurgy' AND -description_tsim: 'Gold')
    # @return [String]
    def search
      search = field_queries.map do |field_query|
        field = field_query[:field] # solr field name, mapped or not
        term = field_query[:term] # query term
        op = char_for opr: field_query[:op]
        "#{op}#{field}:#{term}"
      end
      search.prepend(params.dig(:search, :all)) if params.dig(:search, :all).present?
      search.join(' AND ')
    end

    # compose FilterQuery param
    # @return [String]
    def fq
      filters = params['filter']&.to_h || {}
      filters.delete_if { |k, v| reject_filter(k, v) }
      all_filters = defaults[:fq].merge filters
      all_filters.filter_map do |field, v|
        fq_condition field: field, values: v
      end.join(' AND ') # use AND for all field values (have this attribute AND that attribute)
    end

    # compose Sort param
    # @return [String (frozen)]
    def sort
      sort_field = params.dig :sort, :field
      sort_direction = params.dig :sort, :direction
      sort_field = 'score' if sort_field.blank?
      sort_field = map type: :sort, field: sort_field
      sort_direction = 'asc' if sort_direction.blank?
      "#{sort_field} #{sort_direction}"
    end

    private

    # operator mapping from param value to solr syntax (required[+], excluded[-], optional[ ]) - default to optional
    # see: https://solr.apache.org/guide/solr/latest/query-guide/standard-query-parser.html#boolean-operators-supported-by-the-standard-query-parser
    # @param [Symbol] opr
    # @return [String (frozen)]
    def char_for(opr: :optional)
      case opr.to_sym
      when :required then '+'
      when :excluded then '-'
      else
        ''
      end
    end

    # map params into field query hashes for use in #search
    # @return [Array]
    def field_queries
      search_fields = params.dig(:search, :field)
      Array.wrap(search_fields).filter_map.with_index do |search_field, i|
        solr_field = map type: :search, field: search_field.to_sym
        raise "no map for #{search_field}" unless solr_field

        term = params.dig(:search, :term)&.at(i)
        next if term.blank?

        { field: solr_field,
          term: term,
          op: (params.dig(:search, :opr)&.at(i) || :optional) }
      end
    end

    # @param [Symbol, String] type (search, filter, sort)
    # @param [Symbol, String] field 'friendly' name
    # @return [String] solr field name
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

      Array.wrap(values).compact_blank.map do |value|
        "#{solr_field}: \"#{value}\""
      end.join(' OR ').insert(0, '(').insert(-1, ')') # use OR for particular field values (this OR that collection)
    end

    # Reject values to be used in fq if they are blank, empty, or not in the configured field list
    # @param [Symbol, String] field
    # @param [Sting, Array] values
    # @return [TrueClass, FalseClass]
    def reject_filter(field, values)
      empty_values = values.is_a?(Array) ? values.compact_blank.empty? : values.blank?
      empty_values || !field.to_sym.in?(mapper::Filter.fields)
    end
  end
end
