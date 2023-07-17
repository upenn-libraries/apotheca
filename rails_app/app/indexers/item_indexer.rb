# frozen_string_literal: true

# Custom indexed fields for ItemResource
class ItemIndexer < BaseIndexer
  # @return [Hash{Symbol->Unknown}]
  def to_solr
    return {} unless resource.is_a? ItemResource

    {
      published_bsi: resource.published
    }
  end
end
