# frozen_string_literal: true

module PostgresQueries
  # Custom queries for looking up ValkyrieResources based on derivative metadata
  class Derivative
    def self.queries
      %i[items_without_derivative]
    end

    attr_reader :query_service

    delegate :resource_factory, :run_query, to: :query_service
    delegate :orm_class, to: :resource_factory
    def initialize(query_service:)
      @query_service = query_service
    end

    # Returns ItemResources that do not have a particular item-level derivative
    # @param type [String, Symbol] derivative type
    def items_without_derivative(type:)
      find_resources_without_derivative(resource: 'ItemResource', type: type)
    end

    private

    # Return parameterized SQL query string to query ValkyrieResources based on jsonb derivative conditions

    # @return [String]
    def query
      <<~SQL
        SELECT *
        FROM orm_resources
        WHERE internal_resource = ? AND NOT
              metadata->'derivatives' @> ?
      SQL
    end

    # @param resource[ValkyrieResource]
    # @param type [String, Symbol] derivative type
    def find_resources_without_derivative(resource:, type:)
      derivative_type = [{ type: type }].to_json
      run_query(query, resource.to_s, derivative_type)
    end
  end
end
