# frozen_string_literal: true

module ItemSearch
  # Organize logic for rendering item search form inputs, etc
  class Component < ViewComponent::Base
    attr_reader :mapper, :url, :container

    delegate :documents, :facets, :query, :search_params, to: :container

    # @param [String] url
    # @param [Solr::ResponseContainer] response_container
    # @param [Module<Solr::QueryMaps::Item>] mapper
    def initialize(url:, response_container:, mapper: Solr::QueryMaps::Item)
      @url = url
      @container = response_container
      @mapper = mapper
    end

    def rows_options
      options_for_select([50, 100, 250, 500], params[:rows])
    end

    def sort_fields_options
      options_for_select(mapper::Sort.field_map, params.dig(:sort, :field))
    end

    def sort_directions_options
      options_for_select(
        [%w[Descending desc], %w[Ascending asc]],
        params.dig(:sort, :direction)
      )
    end

    def published_options
      options_for_select(
        [['Yes', true], ['No', false]],
        params.dig(:filter, :published)
      )
    end

    def created_by_options
      options_for_select(
        container.facets.fetch(mapper::Filter.created_by.to_s, []),
        params.dig(:filter, :created_by)
      )
    end

    def updated_by_options
      options_for_select(
        container.facets.fetch(mapper::Filter.updated_by.to_s, []),
        params.dig(:filter, :updated_by)
      )
    end

    def collections_options
      options_for_select(
        container.facets.fetch(mapper::Filter.collection.to_s, []),
        params.dig(:filter, :collection)
      )
    end

    # @param [String, nil] selected
    def search_fields_options(selected: nil)
      options_for_select(
        Solr::QueryMaps::Item::Search.field_map,
        selected
      )
    end

    # @param [String, nil] selected
    def operator_options(selected: nil)
      options_for_select(
        [['', ''], %w[Required required], %w[Excluded excluded]],
        selected
      )
    end

    # extract and organize fielded search values for use in re-rending the form from params
    # @return [Array]
    def fielded_search_params
      search = (search_params[:search] || { field: [], term: [], opr: [] }) # :/
      fields = (0...search[:field].try(:length)).map do |i|
        { field: search[:field][i],
          term: search[:term][i],
          opr: search[:opr][i] }
      end
      Array.wrap fields
    end
  end
end
