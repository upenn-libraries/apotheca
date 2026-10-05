# frozen_string_literal: true

module Item
  module Steps
    include Resource::Steps

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

    def enqueue_ark_metadata_update(*args)
      EnqueueArkMetadataUpdate.new.call(*args)
    end

    def set_thumbnail(*args)
      SetThumbnail.new.call(*args)
    end
  end
end