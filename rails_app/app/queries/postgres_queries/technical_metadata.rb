# frozen_string_literal: true

module PostgresQueries
  # Custom queries for AssetResources based on technical metadata
  class TechnicalMetadata
    def self.queries
      %i[assets_without_dpi assets_by_mime_types]
    end

    attr_reader :query_service

    delegate :resource_factory, :run_query, to: :query_service
    delegate :orm_class, to: :resource_factory
    def initialize(query_service:)
      @query_service = query_service
    end

    def assets_without_dpi
      run_query(assets_without_dpi_query)
    end

    def assets_by_mime_types(*mime_types)
      run_query(assets_by_mime_types_query(*mime_types))
    end

    private

    # Return SQL query string to find all AssetResources without dpi in the technical metadata

    # @return [String]
    def assets_without_dpi_query
      <<~SQL
        SELECT *
        FROM orm_resources
        WHERE internal_resource = 'AssetResource' AND
            metadata->'technical_metadata'->0->'mime_type' = '"image/tiff"'::jsonb AND
            metadata->'technical_metadata'->0->>'dpi' IS NULL
      SQL
    end

    # @return [String]
    def assets_by_mime_types_query(*mime_types)
      <<~SQL
        SELECT *
        FROM orm_resources
        WHERE internal_resource = 'AssetResource' AND
            metadata->'technical_metadata'->0->>'mime_type' IN (#{mime_types.map { |m| "'#{m}'" }.join(',')})
      SQL
    end
  end
end
