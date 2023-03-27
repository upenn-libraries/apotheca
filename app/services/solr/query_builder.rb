# frozen_string_literal: true

module Solr
  # build a solr query hash from expected parameters
  # solr docs: https://solr.apache.org/guide/solr/latest/query-guide/standard-query-parser.html#standard-query-parser-parameters
  class QueryBuilder
    attr_accessor :params, :mapper, :defaults, :rows, :page

    # @param [ActionController::Parameters] params
    # @param [Hash] defaults
    # @param [Module<Solr::QueryMaps::Item>] mapper
    def initialize(params:, defaults:, mapper:)
      @params = params
      @defaults = defaults
      @mapper = mapper
      @rows = params[:rows] || mapper::ROWS_OPTIONS.max
      @page = params[:page] || 1
    end

    # @return [Hash]
    def solr_query
      { q: search,
        rows: rows,
        sort: sort,
        start: start,
        fq: fq }
    end

    # return q param for solr query
    # e.g., (+subject_tsim: 'Metallurgy' -description_tsim: 'Gold')
    # Don't use a boolean operator to join term expressions, rely on operators
    # @return [String]
    def search
      search = Array.wrap(params.dig(:search, :fielded)).filter_map do |field_query|
        solr_field = map type: :search, field: field_query[:field].to_sym
        raise "no map for #{field_query[:field]}" unless solr_field

        term = field_query[:term]
        next if term.blank?

        op = char_for opr: field_query[:opr]
        "#{op}#{solr_field}:\"#{term}\""
      end
      search.prepend("+(#{params.dig(:search, :all)})") if params.dig(:search, :all).present?
      search.join(' ')
    end

    def start
      (page.to_i - 1) * rows.to_i
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
