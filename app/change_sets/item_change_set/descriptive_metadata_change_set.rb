# frozen_string_literal: true

class ItemChangeSet
  # ChangeSet for ItemResource::DescriptiveMetadata nested resource.
  class DescriptiveMetadataChangeSet < Valkyrie::ChangeSet
    ItemResource::DescriptiveMetadata::FREE_TEXT_FIELDS.each do |field|
      property field, multiple: true

      # Remove blank values from array.
      define_method "#{field}=" do |values|
        super(values&.compact_blank)
      end
    end

    ItemResource::DescriptiveMetadata::CONTROLLED_TERM_FIELDS.each do |field|
      collection field, multiple: true, required: false, form: ControlledTermChangeSet,
                        populate_if_empty: ItemResource::DescriptiveMetadata::ControlledTerm
    end

    collection :name, multiple: true, form: NameTermChangeSet,
                      populate_if_empty: ItemResource::DescriptiveMetadata::NameTerm

    validates :title, presence: true, if: ->(metadata) { metadata.bibnumber.blank? }
  end
end
