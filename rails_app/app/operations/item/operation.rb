module Item
  class Operation < ResourceOperation

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





    def enqueue_ark_metadata_update(resource)
      UpdateArkMetadataJob.perform_async(resource.id.to_s)
    end


  end
end
