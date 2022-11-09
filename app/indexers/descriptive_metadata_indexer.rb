# frozen_string_literal: true

# Indexing behavior for descriptive metadata
class DescriptiveMetadataIndexer < BaseIndexer

  # TODO: what about fields in Marmite metadata but not in Item descriptive metadata?
  # @return [Hash]
  def to_solr
    hashes = fields.filter_map do |field|
      public_send(field)
    rescue NoMethodError => _e
      next # TODO: remove upon full implementation?
    end
    hashes.inject(:update) || {}
  end

  def title
    { title_tsim: source.title,
      title_ssim: source.title,
      title_tesim: source.title,
      title_tsi: source.title.first,
      title_ssi: source.title.first,
      title_tesi: source.title.first }
  end

  def collection
    { collection_tsim: descriptive_metadata.collection,
      collection_ssim: descriptive_metadata.collection,
      collection_tesim: descriptive_metadata.collection }
  end

  private

  #   identifier_tsim: alma_descriptive_metadata['identifier'],
  #   creator_tsim: alma_descriptive_metadata['creator'],
  #   provenance_tsim: alma_descriptive_metadata['provenance'],
  #   provenance_tesim: alma_descriptive_metadata['provenance'],
  #   provenance_ssim: alma_descriptive_metadata['provenance'],
  #   description_tsim: alma_descriptive_metadata['description'],
  #   description_tesim: alma_descriptive_metadata['description'],
  #   subject_tsim: alma_descriptive_metadata['subject'],
  #   subject_tesim: alma_descriptive_metadata['subject'],
  #   subject_ssim: alma_descriptive_metadata['subject'],
  #   date_tsim: alma_descriptive_metadata['date'],
  #   personal_name_tsim: alma_descriptive_metadata['personal_name'],
  #   personal_name_tesim: alma_descriptive_metadata['personal_name'],
  #   personal_name_ssim: alma_descriptive_metadata['personal_name'],
  #   geographic_name_tsim: alma_descriptive_metadata['geographic_name'],
  #   geographic_name_tesim: alma_descriptive_metadata['geographic_name'],
  #   geographic_name_ssim: alma_descriptive_metadata['geographic_name'],
  #   item_type_ssim: alma_descriptive_metadata['item_type'],
  #   call_number_tsim: alma_descriptive_metadata['call_number']

  def fields
    ItemResource::DescriptiveMetadata::FIELDS
  end

  def source
    @source ||= bibnumber_present? ? ils_descriptive_metadata : descriptive_metadata
  end

  def ils_descriptive_metadata
    @ils_descriptive_metadata ||= extracted_metadata
  end

  # Provide Marmite metadata in an object-like fashion
  # @return [anonymous Struct]
  def extracted_metadata
    metadata_hash = MetadataExtractor::Marmite
                    .new(url: Settings.marmite.url)
                    .descriptive_metadata(resource.descriptive_metadata.bibnumber.first)
    Struct.new('Metadata', *metadata_hash.keys).new(*metadata_hash.values)
  end

  def descriptive_metadata
    @descriptive_metadata ||= resource.try :descriptive_metadata
  end

  def bibnumber_present?
    return false unless descriptive_metadata

    descriptive_metadata.bibnumber.first.present? # all desc md is multivalued
  end
end
