# frozen_string_literal: true

# Query class that fetches Item resources based on field values.
class ItemQueries
  def self.queries
    %i[find_by_unique_identifier]
  end

  attr_reader :query_service

  delegate :resource_factory, :run_query, :find_inverse_references_with_type_query, to: :query_service
  delegate :orm_class, to: :resource_factory

  def initialize(query_service:)
    @query_service = query_service
  end

  # Looks up resource by unique_identifier.
  #
  # @param [String] unique_identifier
  # @return [Valkyrie::Resource, nil] resource or nil if no matching resource found
  def find_by_unique_identifier(unique_identifier:)
    run_field_query(:unique_identifier, unique_identifier).first || nil
  end

  private

  def run_field_query(field, value)
    internal_array = "{\"#{field}\": [\"#{value}\"]}"
    run_query(find_inverse_references_with_type_query, internal_array, ItemResource)
  end
end
