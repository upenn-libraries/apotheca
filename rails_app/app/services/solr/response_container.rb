# frozen_string_literal: true

module Solr
  # provide a nice container for handling solr response and related query info in controllers
  class ResponseContainer
    attr_reader :documents, :facets, :query, :search_params, :total_count

    # @param [Array] documents
    # @param [Hash] facet_data
    # @param [ActionController::Parameters] search_params
    # @param [Hash, String, nil] query
    # @param [Integer] total_count
    def initialize(documents:, facet_data:, search_params:, total_count:, query: nil)
      @documents = documents
      @facets = facets_to_hash(facet_data: facet_data)
      @search_params = search_params
      @query = query.to_s
      @total_count = total_count
    end

    # Build a Kaminari-wrapped array for feeding to the paginator renderer in the view. Parameters here ensure proper
    # rendering of active page, number of pages, etc. No pagination is actually performed on the documents array.
    # See: https://github.com/kaminari/kaminari#paginating-a-generic-array-object
    # @return [Kaminari::PaginatableArray]
    def paginator
      Kaminari.paginate_array(documents, total_count: total_count, limit: search_params[:rows])
              .page(search_params[:page]).per(search_params[:rows])
    end

    private

    # Convert Solr facet response data structure to a nicer hash for view purposes
    # @param [Hash] facet_data
    # @return [Hash]
    def facets_to_hash(facet_data:)
      facet_data.transform_values do |v|
        v.each_slice(2).map do |a, b|
          ["(#{b}) #{a}", a]
        end
      end
    end
  end
end
