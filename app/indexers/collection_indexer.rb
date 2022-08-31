# frozen_string_literal: true

# Indexing behavior for Collection field from descriptive metadata
class CollectionIndexer < BaseIndexer
  # @return [Hash]
  def to_solr
    return {} unless descriptive_metadata

    {
      collection_tsim: descriptive_metadata.collection,
      collection_ssim: descriptive_metadata.collection,
      collection_tesim: descriptive_metadata.collection
    }
  end

  def descriptive_metadata
    @descriptive_metadata ||= @resource.try :descriptive_metadata
  end
end
