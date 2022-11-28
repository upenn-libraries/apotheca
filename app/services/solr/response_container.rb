# frozen_string_literal: true

module Solr
  # provide a nice container for handling solr response in controllers
  class ResponseContainer
    attr_reader :documents, :facets, :query

    def initialize(documents:, facet_data:, query: nil)
      @documents = documents
      @facets = facets_to_hash(facet_data: facet_data)
      @query = query.to_s
    end

    private

    def facets_to_hash(facet_data:)
      facet_data.transform_values do |v|
        v.each_slice(2).map do |a, b|
          ["#{a} (#{b})", a]
        end
      end
    end
  end
end
