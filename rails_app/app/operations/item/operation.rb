module Item
  class Operation < Dry::Operation

    def create_change_set(attributes)
      resource = attributes.delete(:resource) || ItemResource.new
      change_set = ItemChangeSet.new(resource)

      begin
        change_set.validate(attributes)
        Success(change_set)
      rescue StandardError => e
        Failure(error: :error_creating_change_set, exception: e)
      end
    end

    def set_thumbnail(change_set)
      if change_set.thumbnail_asset_id.blank?
        thumbnail_id = if change_set.structural_metadata.arranged_asset_ids&.any?
                         change_set.structural_metadata.arranged_asset_ids.first
                       elsif change_set.asset_ids&.any?
                         change_set.asset_ids.first
                       end

        change_set.thumbnail_asset_id = thumbnail_id
      end

      Success(change_set)
    end

    def set_updated_by(change_set)
      change_set.updated_by = change_set.created_by if change_set.updated_by.blank?

      Success(change_set)
    end

    def validation(change_set)
      if change_set.valid?
        Success(change_set)
      else
        Failure(error: :validation_failed, change_set: change_set)
      end
    end

    def save(change_set)
      resource = change_set.sync

      begin
        saved_resource = persister.save(resource: resource)
        Success(saved_resource)
      rescue StandardError => e
        Failure(error: :error_saving_resource, exception: e, change_set: change_set)
      end
    end

    def enqueue_ark_metadata_update(resource)
      UpdateArkMetadataJob.perform_async(resource.id.to_s)
    end

    private

    def persister
      Valkyrie::MetadataAdapter.find(:postgres_solr_persister).persister
    end
  end
end
