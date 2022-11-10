# frozen_string_literal: true

# Indexing behavior for descriptive metadata
class DescriptiveMetadataIndexer < BaseIndexer
  RESOURCE_METADATA_JSON_FIELD = :resource_metadata_ss
  ILS_METADATA_JSON_FIELD = :ils_metadata_ss
  # @return [Hash]
  def to_solr
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
    ItemResource::DescriptiveMetadata::FIELDS # MARC Metadata may have more fields, but they should be ignored
  end

  # @return [Hash]
  def source
    @source ||= merged_metadata_sources
  end

  # @return [Hash]
  def ils_descriptive_metadata
    @ils_descriptive_metadata ||= extracted_metadata
  end

  # @return [Hash]
  def merged_metadata_sources
    fields.index_with do |field|
      val = descriptive_metadata.public_send(field)
      if val.blank? && bibnumber_present?
        ils_descriptive_metadata[field.to_s]
      else
        val
      end
    end
  end

  # Provide Marmite metadata in an object-like fashion
  def extracted_metadata
    MetadataExtractor::Marmite.new(url: Settings.marmite.url)
                              .descriptive_metadata(resource.descriptive_metadata.bibnumber.first)
  end

  def descriptive_metadata
    @descriptive_metadata ||= resource.try :descriptive_metadata
  end

  # @return [TrueClass, FalseClass]
  def bibnumber_present?
    return false unless descriptive_metadata

    descriptive_metadata.bibnumber.first.present? # all desc md is multivalued
  end
end
