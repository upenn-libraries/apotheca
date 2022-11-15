# frozen_string_literal: true

# Custom indexed fields for ItemResource
class ItemIndexer
  # @return [Hash{Symbol->Unknown}]
  def to_solr
    {
      published_bsi: resource.published
    }
  end
end
