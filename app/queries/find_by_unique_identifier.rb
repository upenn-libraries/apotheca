# frozen_string_literal: true

# Query class that fetches resources by unique_identifier
class FindByUniqueIdentifier
  def self.queries
    [:find_by_unique_identifier]
  end

  attr_reader :query_service

  delegate :resource_factory, :run_query, :find_inverse_references_query, to: :query_service
  delegate :orm_class, to: :resource_factory

  def initialize(query_service:)
    @query_service = query_service
  end

  # Looks up resource by unique_identifier
  #
  # @param [String] unique_identifier
  # @return [Valkyrie::Resource, nil] resource or nil if no matching resource found
  def find_by_unique_identifier(unique_identifier:)
    internal_array = "{\"unique_identifier\": [\"#{unique_identifier}\"]}"
    run_query(find_inverse_references_query, internal_array).first || nil
  end
end
