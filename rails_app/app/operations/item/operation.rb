# frozen_string_literal: true

module Item
  # Parent class for Item Operations. Includes reuseable steps for Item operations.
  class Operation < Resource::Operation
    alias find_item find_resource
    alias delete_item delete_resource

    def resource_class
      ItemResource
    end

    def change_set_class
      ItemChangeSet
    end

    def update_ark_metadata_later(*args)
      Steps::UpdateArkMetadataLater.new.call(*args)
    end

    def set_thumbnail(*args)
      Steps::SetThumbnail.new.call(*args)
    end
  end
end
