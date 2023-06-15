# frozen_string_literal: true

class ItemChangeSet
  class DescriptiveMetadataChangeSet
    # Change set for ItemResource::DescriptiveMetadata::ControlledTerm nested resource
    class ControlledTermChangeSet < Valkyrie::ChangeSet
      property :label, multiple: false, required: true
      property :uri, multiple: false, required: false

      validates :label, presence: true
    end
  end
end