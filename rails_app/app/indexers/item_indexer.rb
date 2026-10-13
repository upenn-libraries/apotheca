# frozen_string_literal: true

# Custom indexed fields for ItemResource
class ItemIndexer < BaseIndexer
  # @return [Hash{Symbol->Unknown}]
  def to_solr
    return {} unless resource.is_a? ItemResource

    { uuid_ssi: resource.id.to_s,
      unique_identifier_ssim: resource.unique_identifier,
      published_bsi: resource.published == true,
      first_published_at_dtsi: first_published_date,
      last_published_at_dtsi: last_published_date,
      date_created_dtsi: created_date }
  end

  private

  def first_published_date
    resource.first_published_at&.to_fs :solr
  end

  def last_published_date
    resource.first_published_at&.to_fs :solr
  end

  def created_date
    resource.date_created.to_fs :solr
  end
end
