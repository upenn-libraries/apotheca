# frozen_string_literal: true

# query class for returning stored ILS metadata from an ItemResource
class ItemIlsMetadata
  attr_reader :query_service

  delegate :connection, to: :query_service # RSolr
  delegate :resource_factory, to: :query_service

  def self.queries
    [:ils_metadata_for]
  end

  # @param [Object] query_service
  def initialize(query_service:)
    @query_service = query_service
  end

  # @param [Valkyrie::ID | String] id
  # @return [Hash]
  def ils_metadata_for(id:)
    doc = connection.get('select', params: {
      q: "id:\"#{id}\"",
      fl: DescriptiveMetadataIndexer::ILS_METADATA_JSON_FIELD, rows: 1
    })['response']['docs'].first
    return if doc.blank?

    JSON.parse doc[DescriptiveMetadataIndexer::ILS_METADATA_JSON_FIELD.to_s]
  end
end
