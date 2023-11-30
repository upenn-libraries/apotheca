# frozen_string_literal: true

# Transaction that refreshes ILS metadata by re-persisting an item to the solr index
class RefreshIlsMetadata
  include Dry::Transaction(container: Container)

  step :find_item, with: 'item_resource.find_resource'
  step :require_updated_by, with: 'attributes.require_updated_by'
  step :validate_bibnumber
  step :save
  tee :record_event

  def validate_bibnumber(resource:, **attributes)
    if resource.descriptive_metadata.bibnumber.blank?
      Failure(error: :no_bib_number)
    else
      Success(resource: resource, **attributes)
    end
  end

  def save(resource:, **attributes)
    persister.save(resource: resource) # returns true if successful
    Success(resource: resource, **attributes)
  rescue StandardError => e
    Failure(error: :error_persisting_to_solr_index, exception: e)
  end

  def record_event(resource:, updated_by:)
    ResourceEvent.record_event_for(
      resource: resource, event_type: :refresh_ils_metadata, json: false, initiated_by: updated_by
    )
  end

  private

  def persister
    Valkyrie::MetadataAdapter.find(:index_solr).persister
  end
end
