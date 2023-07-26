# frozen_string_literal: true

# Indexing behavior for the fields defined in ItemResource::DescriptiveMetadata Resource
class DescriptiveMetadataIndexer < BaseIndexer
  RESOURCE_METADATA_JSON_FIELD = :resource_metadata_ss
  ILS_METADATA_JSON_FIELD = :ils_metadata_ss

  # Constructs hash for aggregation of descriptive metadata into the Solr update data.
  # Adds fields from the DescriptiveMetadata mapper using each field name from those defined in
  # the ItemResource::DescriptiveMetadata Resource
  # @return [Hash]
  def to_solr
    return {} unless descriptive_metadata

    mapper = IndexingMappers::DescriptiveMetadata.new data: source
    hashes = fields.filter_map do |field|
      mapper.public_send(field) if mapper.respond_to?(field)
    end
    ret = hashes.inject(:update) || {}
    ret[RESOURCE_METADATA_JSON_FIELD] = descriptive_metadata.to_json
    ret[ILS_METADATA_JSON_FIELD] = ils_descriptive_metadata.to_json if bibnumber_present?
    ret
  end

  # @return [Array]
  def fields
    ItemResource::DescriptiveMetadata::Fields.all
  end

  # @return [Hash]
  def source
    @source ||= merged_metadata_sources
  end

  # @return [Hash]
  def ils_descriptive_metadata
    @ils_descriptive_metadata ||= extracted_metadata
  end

  # Hash uniting the ILS and Resource field data, preferring Resource metadata and only including ILS
  # metadata if a bibnumber is present in the Resource
  # @return [Hash]
  def merged_metadata_sources
    fields.index_with do |field|
      val = descriptive_metadata[field]
      if val.blank? && bibnumber_present?
        ils_descriptive_metadata[field]
      else
        val
      end
    end
  end

  # @return [Hash]
  def extracted_metadata
    MetadataExtractor::Marmite.new(url: Settings.marmite.url)
                              .descriptive_metadata(resource.descriptive_metadata.bibnumber.first.value)
  end

  # @return [Hash]
  def descriptive_metadata
    @descriptive_metadata ||= resource.try(:descriptive_metadata).try(:to_json_export)
  end

  # @return [TrueClass, FalseClass]
  def bibnumber_present?
    return false unless descriptive_metadata

    descriptive_metadata.dig(:bibnumber, 0, :value).present? # all desc md is multivalued
  end
end
