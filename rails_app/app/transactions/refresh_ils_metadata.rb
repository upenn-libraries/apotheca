# frozen_string_literal: true

# Transaction that refreshes ILS metadata by re-persisting an item to the solr index
class RefreshIlsMetadata
  include Dry::Transaction(container: Container)

  step :find_item, with: 'item_resource.find_resource'
  step :validate_bibnumber
  step :save

  def validate_bibnumber(resource:)
    if resource.descriptive_metadata.bibnumber.blank?
      Failure(error: :no_bib_number)
    else
      Success(resource: resource)
    end
  end

  def save(resource:)
    # the index_solr persister#save returns true if successful; it does not return the saved resource
    persisted_to_solr_index = persister.save(resource: resource)
    Success(persisted_to_solr_index)
  rescue StandardError => e
    Failure(error: :error_persisting_to_solr_index, exception: e)
  end

  def persister
    Valkyrie::MetadataAdapter.find(:index_solr).persister
  end
end
