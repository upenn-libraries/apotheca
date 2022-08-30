# frozen_string_literal: true

# Indexing behavior for Title field from descriptive metadata
class TitleIndexer < BaseIndexer
  # @return [Hash]
  def to_solr
    return {} unless descriptive_metadata

    {
      title_tsim: descriptive_metadata.title,
      title_ssim: descriptive_metadata.title,
      title_tesim: descriptive_metadata.title,
      title_tsi: descriptive_metadata.title.first,
      title_ssi: descriptive_metadata.title.first,
      title_tesi: descriptive_metadata.title.first
    }
  end

  def descriptive_metadata
    @descriptive_metadata ||= @resource.try :descriptive_metadata
  end
end
