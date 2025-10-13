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
      options_for_select(mapper::ROWS_OPTIONS, params[:rows])
    end

    def sort_fields_options
      options_for_select(mapper::Sort.field_map,
                         search_params.dig(:sort, :field) || SolrQueries::ItemIndex::DEFAULT_SORT[:field])
    end

    def sort_directions_options
      options_for_select(
        [%w[Descending desc], %w[Ascending asc]],
        search_params.dig(:sort, :direction) || SolrQueries::ItemIndex::DEFAULT_SORT[:direction]
      )
    end

    def published_options
      options_for_select(
        [['Yes', true], ['No', false]],
        search_params.dig(:filter, :published)
      )
    end

    def created_by_options
      options_for_select(
        container.facets.fetch(mapper::Filter::MAP[:created_by].to_s, []),
        search_params.dig(:filter, :created_by)
      )
    end

    def updated_by_options
      options_for_select(
        container.facets.fetch(mapper::Filter::MAP[:updated_by].to_s, []),
        search_params.dig(:filter, :updated_by)
      )
    end

    def collections_options
      options_for_select(
        container.facets.fetch(mapper::Filter::MAP[:collection].to_s, []),
        search_params.dig(:filter, :collection)
      )
    end

    # @param [String, nil] selected
    def search_fields_options(selected: nil)
      options_for_select(
        Solr::QueryMaps::Item::Search.field_map.sort,
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

    # extract fielded search values for use in re-rending the form from params
    # @return [Array]
    def fielded_search_params
      search_params.dig(:search, :fielded) || [{}]
    end
  end
end
