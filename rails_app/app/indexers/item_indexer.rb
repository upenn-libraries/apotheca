# frozen_string_literal: true

# Custom indexed fields for ItemResource. Valkyrie sees that the Resource fields are indexed, but for the fields here
# we want more explicit control over formatting or Solr field type.
class ItemIndexer < BaseIndexer
  # @return [Hash{Symbol->Unknown}]
  def to_solr
    return {} unless resource.is_a? ItemResource

    { published_bsi: resource.published == true,
      first_published_at_dtsi: resource.first_published_at&.to_fs(:solr),
      last_published_at_dtsi: resource.first_published_at&.to_fs(:solr),
      date_created_dtsi: resource.date_created.to_fs(:solr) }
  end
end
