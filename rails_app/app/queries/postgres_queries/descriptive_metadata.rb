# frozen_string_literal: true

module PostgresQueries
  # Custom queries for ItemResource's descriptive metadata.
  class DescriptiveMetadata
    def self.queries
      %i[items_with_bibnumber]
    end

    attr_reader :query_service

    delegate :resource_factory, :run_query, to: :query_service
    delegate :orm_class, to: :resource_factory

    def initialize(query_service:)
      @query_service = query_service
    end

    # Return all ItemResources with a bibnumber
    #
    # @return [Enumerator::Lazy<AssetResource>]
    def items_with_bibnumber
      run_query(items_with_bibnumber_query)
    end

    private

    # Return SQL query string to find all ItemResources with a bibnumber
    #
    # @return [String]
    def items_with_bibnumber_query
      <<-SQL
        SELECT *
        FROM orm_resources
        WHERE internal_resource = 'ItemResource' AND
              jsonb_array_length(metadata->'descriptive_metadata'->0->'bibnumber') > 0
      SQL
    end
  end
end
