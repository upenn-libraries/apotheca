# frozen_string_literal: true

module Solr
  # provide a nice container for handling solr response and related query info in controllers
  class ResponseContainer
    attr_reader :documents, :facets, :query, :search_params

    # @param [Array] documents
    # @param [Hash] facet_data
    # @param [ActionController::Parameters] search_params
    # @param [Hash, String, nil] query
    def initialize(documents:, facet_data:, search_params:, query: nil)
      @documents = documents
      @facets = facets_to_hash(facet_data: facet_data)
      @search_params = search_params
      @query = query.to_s
    end

    private

    # Convert Solr facet response data structure to a nicer hash for view purposes
    # @param [Hash] facet_data
    # @return [Hash]
    def facets_to_hash(facet_data:)
      facet_data.transform_values do |v|
        v.each_slice(2).map do |a, b|
          ["#{a} (#{b})", a]
        end
      end
    end
  end
end
