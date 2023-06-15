# frozen_string_literal: true

class ItemChangeSet
  class DescriptiveMetadataChangeSet
    # ChangeSet for ItemResource::DescriptiveMetadata::NameTerm nested resource
    class NameTermChangeSet < ControlledTermChangeSet
      collection :role, multiple: true, required: false, form: ControlledTermChangeSet,
                        populate_if_empty: ItemResource::DescriptiveMetadata::ControlledTerm
    end
  end
end
