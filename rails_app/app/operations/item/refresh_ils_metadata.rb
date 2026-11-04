# frozen_string_literal: true

module Item
  # Operation that refreshes the ILS metadata stored with an Item.
  class RefreshIlsMetadata < Operation
    # Executes this operation
    # @param id [String] UUID of Item to refresh
    # @param updated_by [String] email of user who initiated this operation
    def call(id:, updated_by:)
      resource = step find_item(id)
      step validate_bibnumber(resource)
      step solr_save(resource)

      record_event(resource, updated_by)
      republish_later(resource, updated_by)

      resource
    end

    # @param resource [ItemResource]
    def validate_bibnumber(resource)
      if resource.descriptive_metadata.bibnumber.blank?
        Failure error: :no_bib_number
      else
        Success resource: resource
      end
    end

    # Save resource to the Solr persister only, triggering an ILS metadata update
    # @param resource [ItemResource]
    def solr_save(resource)
      persister.save resource: resource
      Success resource: resource
    rescue StandardError => e
      Failure(error: :error_persisting_to_solr_index, exception: e)
    end

    # @param resource [ItemResource]
    # @param updated_by [String] email of user who initiated this operation
    def record_event(resource, updated_by)
      ResourceEvent.record_event_for(
        resource: resource, event_type: :refresh_ils_metadata, json: false, initiated_by: updated_by
      )
    end

    # @param resource [ItemResource]
    # @param updated_by [String] email of user who initiated this operation
    def republish_later(resource, updated_by)
      return unless resource.published

      PublishItemJob.perform_async(resource.id.to_s, updated_by)
    end

    private

    def persister
      Valkyrie::MetadataAdapter.find(:index_solr).persister
    end
  end
end
