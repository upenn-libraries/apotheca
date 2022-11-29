# frozen_string_literal: true

module ItemSearch
  # Organize logic for rendering item search form inputs, etc
  class Component < ViewComponent::Base
    attr_reader :mapper, :url, :container

    delegate :facets, :query, to: :container

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

    def search_fields_options
      options_for_select(
        Solr::QueryMaps::Item::Search.field_map # TODO: selected
      )
    end

    def operator_options
      options_for_select(
        [['None', ''], %w[Required required], %w[Excluded excluded]] # TODO: selected
      )
    end
  end
end
