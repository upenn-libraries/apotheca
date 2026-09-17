# frozen_string_literal: true

module Item
  # Parent class for Item Operations. Includes reuseable steps for Item operations.
  class Operation < Resource::Operation
    def resource_class
      ItemResource
    end

    def change_set_class
      ItemChangeSet
    end

    def enqueue_ark_metadata_update(*args)
      Steps::EnqueueArkMetadataUpdate.new.call(*args)
    end

    def set_thumbnail(*args)
      Steps::SetThumbnail.new.call(*args)
    end
  end
end
